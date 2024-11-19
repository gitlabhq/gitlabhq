# frozen_string_literal: true

# This script deletes users with a username starting with "qa-user-" or "test-user-"
#   - If `dry_run` is true the script will list the users to be deleted, but it won't delete them
#   - Specify `exclude_users` as a comma-separated list of usernames to not delete.

# Required environment variables: GITLAB_QA_ADMIN_ACCESS_TOKEN, GITLAB_QA_ACCESS_TOKEN, and GITLAB_ADDRESS
#   - GITLAB_QA_ADMIN_ACCESS_TOKEN must have admin API access

# Optional environment variables: DELETE_BEFORE (default: 1 day ago)
#   - Set DELETE_BEFORE to only delete users that were created before a given date, otherwise defaults to 1 day ago

# Run `rake delete_test_users`

module QA
  module Tools
    class DeleteTestUsers < DeleteResourceBase
      EXCLUDE_USERS = %w[gitlab-qa gitlab-qa-user-for-ai gitlab-qa-user-for-jetbrains glab-test-bot].freeze

      def initialize(dry_run: false, exclude_users: nil)
        super(dry_run: dry_run)

        raise ArgumentError, "Please provide GITLAB_QA_ADMIN_ACCESS_TOKEN" unless ENV['GITLAB_QA_ADMIN_ACCESS_TOKEN']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: ENV['GITLAB_QA_ADMIN_ACCESS_TOKEN'])
        @exclude_users = Array(exclude_users.to_s.split(',')) + EXCLUDE_USERS
        @type = 'user'
      end

      def run
        users = fetch_test_users

        results = delete_test_users(users)

        log_results(results)
      end

      private

      def fetch_test_users
        users = fetch_resources("/users")

        users.select do |user|
          user[:username].start_with?('qa-user-', 'test-user-') \
            && user[:name].start_with?('QA User', 'QA Test') \
            && @exclude_users.exclude?(user[:username]) \
            && Date.parse(user.fetch(:created_at, Date.today.to_s)) < @delete_before
        end
      end

      def delete_test_users(users)
        if @dry_run
          log_dry_run_output(users)
          return
        end

        if users.empty?
          logger.info("No users found\n")
          return
        end

        delete_resources(users, true, hard_delete: 'true')
      end

      def resource_request(user, **options)
        Runtime::API::Request.new(@api_client, "/users/#{user[:id]}", **options).url
      end
    end
  end
end
