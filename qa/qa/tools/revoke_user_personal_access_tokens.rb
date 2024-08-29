# frozen_string_literal: true

# This script revokes all active personal access tokens that include `api-pat-` in the name owned by a given
# USER_ID or USER_NAME up to a given date DELETE_BEFORE (Date.today - 3 by default)
#   - If `dry_run` is true the script will list tokens to be revoked, but it won't revoke them

# Required environment variables: GITLAB_QA_ACCESS_TOKEN, GITLAB_ADDRESS, and USER_ID or USER_NAME
#   - USER_NAME username of the user whose tokens are to be revoked
#     OR
#   - USER_ID the id of the user whose tokens are to be revoked.

# Optional environment variables: DELETE_BEFORE (default: 3 days ago), ALL_TOKENS (default: false)
#   - Set DELETE_BEFORE to revoke only tokens that were created before the given date (default: 3 days ago)
#   - Set ALL_TOKENS to true to revoke all tokens for the given user except ones named 'cleanup-token' as we use that to
#     run this script in a scheduled pipeline. Else only tokens with `api-pat-` in the name will be revoked.
#
# Run `rake revoke_user_pats`
#
# @example
#   # Do a dry run of revoking access tokens for gitlab-qa-user1 up to 2024-04-20
#   GITLAB_ADDRESS=https://gitlab.com \
#   GITLAB_QA_ACCESS_TOKEN=<token for gitlab-qa-user1> \
#   USER_ID=<user id for gitlab-qa-user1> \
#   DELETE_BEFORE=2024-04-20 \
#   bundle exec rake "revoke_user_pats[true]"

module QA
  module Tools
    class RevokeUserPersonalAccessTokens < DeleteResourceBase
      EXCLUDE_TOKENS = %w[
        cleanup-token
        api-pat-gitlab-qa
        GPT_staging_CI_test_token
        GITLAB_QA_ACCESS_TOKEN
        GITLAB_QA_ADMIN_ACCESS_TOKEN
      ].freeze
      TEST_TOKEN_BASE = 'api-pat-'

      def initialize(dry_run: false)
        unless ENV['USER_ID'] || ENV['USER_NAME']
          raise ArgumentError, "Please provide USER_ID or USER_NAME environment variable"
        end

        super

        @type = 'token'
        @delete_before = Date.parse(ENV['DELETE_BEFORE'] || (Date.today - 3).to_s)
        @total = 0
        @all_tokens = ENV['ALL_TOKENS']
      end

      def run
        user_id = ENV['USER_ID'] || fetch_qa_user_id(ENV['USER_NAME'])
        logger.info("Fetching QA access tokens for user (id: #{user_id}) on #{ENV['GITLAB_ADDRESS']}...")

        tokens = fetch_tokens(user_id)
        revoke_tokens(tokens) unless tokens.blank?

        logger.info("Revoked #{@total} personal access tokens for user (id: #{user_id}) on #{ENV['GITLAB_ADDRESS']}")
        logger.info("Done")
      end

      private

      attr_reader :dry_run, :page_no, :api_client
      alias_method :dry_run?, :dry_run

      def fetch_tokens(user_id)
        fetched_tokens = []
        raw_tokens = fetch_resources("/personal_access_tokens?user_id=#{user_id}&revoked=false")
        filtered_tokens = filter_tokens(raw_tokens)

        if filtered_tokens.empty?
          logger.info("Filtered out all tokens")
          return
        end

        tokens = filtered_tokens
          .map do |token|
            {
              id: token[:id],
              name: token[:name],
              created_at: token[:created_at],
              active: token[:active]
            }
          end
        fetched_tokens.concat(tokens)

        fetched_tokens
      end

      def filter_tokens(tokens)
        if @all_tokens
          tokens.select do |token|
            EXCLUDE_TOKENS.exclude?(token[:name]) \
            && Date.parse(token[:created_at]) < @delete_before
          end
        else
          tokens.select do |token|
            token[:name].include?(TEST_TOKEN_BASE) \
            && EXCLUDE_TOKENS.exclude?(token[:name]) \
            && Date.parse(token[:created_at]) < @delete_before
          end
        end
      end

      def revoke_tokens(tokens)
        if dry_run?
          logger.info("The following #{tokens.count} tokens would be revoked:")
        else
          logger.info("Revoking #{tokens.count} tokens...")
        end

        tokens.each do |token|
          if dry_run?
            logger.info("Token name: #{token[:name]}, id: #{token[:id]}, created at: #{token[:created_at]}")
          else
            request_url = Runtime::API::Request.new(api_client, "/personal_access_tokens/#{token[:id]}").url

            logger.info("Revoking token with name: #{token[:name]}, " \
             "id: #{token[:id]}, created at: #{token[:created_at]} ")

            delete_response = delete(request_url)

            if success?(delete_response&.code)
              @total += 1
              logger.info("\e[32mSUCCESS\e[0m\n")
            else
              logger.error("\e[31mFAILED - #{delete_response}\e[0m\n")
            end
          end
        end
      end
    end
  end
end
