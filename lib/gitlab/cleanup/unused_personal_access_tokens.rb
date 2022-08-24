# frozen_string_literal: true

module Gitlab
  module Cleanup
    # Unused active Personal Access Tokens pose a risk to organizations
    # in that they may have been, or may be, leaked to unauthorized
    # individuals. They are likely providing little / no current value
    # because they are not actively being used, and should therefore be
    # proactively revoked.
    class UnusedPersonalAccessTokens
      # By default tokens that haven't been used for over 1 year will
      # be revoked
      DEFAULT_TIME_PERIOD = 1.year
      # To prevent inadvertently revoking actively used tokens, we
      # provide a minimum time
      MINIMUM_TIME_PERIOD = 1.day

      attr_reader :logger, :last_used_before, :revocation_time, :group

      def initialize(last_used_before: DEFAULT_TIME_PERIOD.ago.beginning_of_day, logger: nil, group_full_path:)
        # binding.pry
        # Ensure last_used_before is a Time and far enough in the past
        @last_used_before = last_used_before

        # rubocop: disable CodeReuse/ActiveRecord
        @group = Group.find_by_full_path(group_full_path)
        # rubocop: enable CodeReuse/ActiveRecord
        raise "Group with full_path #{group_full_path} not found" unless @group
        raise "Invalid time: #{@last_used_before}" unless @last_used_before <= MINIMUM_TIME_PERIOD.ago

        # Use a static revocation time to make correlation of revoked
        # tokens easier, should it be needed.
        @revocation_time = Time.current.utc
        @logger = logger || Gitlab::AppJsonLogger

        raise "Invalid logger: #{@logger}" unless @logger.respond_to?(:info) && @logger.respond_to?(:warn)
      end

      # Revokes unused personal access tokens.
      # A dry run is performed by default, logging what would be
      # revoked. Pass `dry_run: false` explicitly to revoke tokens.
      def run!(dry_run: true)
        # rubocop:disable Rails/Output
        if dry_run
          puts "Dry running. No changes will be made"
        else
          puts "Revoking access tokens from before #{last_used_before}..."
        end
        # rubocop:enable Rails/Output

        logger.info(
          dry_run: dry_run,
          group_full_path: group.full_path,
          message: "Looking for Personal Access Tokens " \
          "last used before #{last_used_before}..."
        )

        # rubocop:disable Cop/InBatches
        revocable_tokens.in_batches do |access_tokens|
          revoke_batch(access_tokens, dry_run)
        end
        # rubocop:enable Cop/InBatches
      end

      private

      def revocable_tokens
        PersonalAccessToken
          .active
          .owner_is_human
          .last_used_before(last_used_before)
          .for_users(group.users)
      end

      def revoke_batch(access_tokens, dry_run)
        # Capture a simplified set of attributes for logging and for
        # determining when an error has led some records to not be
        # updated
        attrs = access_tokens.as_json(only: [:id, :user_id])

        # Use `update_all` to bypass any validations which might
        # prevent revocation. Manually specify updated_at.
        affected_row_count = dry_run ? 0 : access_tokens.update_all(revoked: true, updated_at: @revocation_time)

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
