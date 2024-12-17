# frozen_string_literal: true

module Gitlab
  module Cleanup
    class PersonalAccessTokens
      # By default tokens that haven't been used for over 1 year will be revoked
      DEFAULT_TIME_PERIOD = 1.year
      # To prevent inadvertently revoking all tokens, we provide a minimum time
      MINIMUM_TIME_PERIOD = 1.day

      attr_reader :logger, :cut_off_date, :revocation_time, :group

      def initialize(group_full_path:, cut_off_date: DEFAULT_TIME_PERIOD.ago.beginning_of_day, logger: nil)
        @cut_off_date = cut_off_date

        @group = Group.find_by_full_path(group_full_path)
        raise "Group with full_path #{group_full_path} not found" unless @group
        raise "Invalid time: #{@cut_off_date}" unless @cut_off_date <= MINIMUM_TIME_PERIOD.ago

        # Use a static revocation time to make correlation of revoked
        # tokens easier, should it be needed.
        @revocation_time = Time.current.utc
        @logger = logger || Gitlab::AppJsonLogger

        raise "Invalid logger: #{@logger}" unless @logger.respond_to?(:info) && @logger.respond_to?(:warn)
      end

      def run!(dry_run: true, revoke_active_tokens: false)
        # rubocop:disable Rails/Output
        if dry_run
          puts "Dry running. No changes will be made"
        elsif revoke_active_tokens
          puts "Revoking used and unused access tokens created before #{cut_off_date}..."
        else
          puts "Revoking access tokens last used and created before #{cut_off_date}..."
        end
        # rubocop:enable Rails/Output

        tokens_to_revoke = revocable_tokens(revoke_active_tokens)

        # rubocop:disable Cop/InBatches
        tokens_to_revoke.in_batches do |access_tokens|
          revoke_batch(access_tokens, dry_run)
        end
        # rubocop:enable Cop/InBatches
      end

      private

      def revocable_tokens(revoke_active_tokens)
        if revoke_active_tokens
          PersonalAccessToken
            .active
            .owner_is_human
            .created_before(cut_off_date)
            .for_users(group.group_members.select(:user_id))
            .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/436661")
        else
          PersonalAccessToken
            .active
            .owner_is_human
            .last_used_before_or_unused(cut_off_date)
            .for_users(group.group_members.select(:user_id))
            .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/436661")
        end
      end

      def revoke_batch(access_tokens, dry_run)
        # Capture a simplified set of attributes for logging and for
        # determining when an error has led some records to not be
        # updated
        attrs = access_tokens.as_json(only: [:id, :user_id])

        cross_joins_issue = "https://gitlab.com/gitlab-org/gitlab/-/issues/436661"
        affected_row_count = ::Gitlab::Database.allow_cross_joins_across_databases(url: cross_joins_issue) do
          # Use `update_all` to bypass any validations which might
          # prevent revocation. Manually specify updated_at.
          dry_run ? 0 : access_tokens.update_all(revoked: true, updated_at: @revocation_time)
        end

        message = {
          dry_run: dry_run,
          message: "Revoke token batch",
          token_count: attrs.size,
          updated_count: affected_row_count,
          tokens: attrs,
          group_full_path: group.full_path
        }

        # rubocop:disable Rails/Output
        if dry_run
          puts "Dry run complete. #{attrs.size} rows would be affected"
          logger.info(message)
        elsif affected_row_count.eql?(attrs.size)
          puts "Finished. #{attrs.size} rows affected"
          logger.info(message)
        else
          # :nocov:
          puts "ERROR. #{affected_row_count} tokens deleted, #{attrs.size} tokens should have been deleted"
          logger.warn(message)
          # :nocov:
        end
        # rubocop:enable Rails/Output
      end
    end
  end
end
