# frozen_string_literal: true

# This script deletes top level groups owned by the user who owns the GITLAB_QA_ACCESS_TOKEN (gitlab-qa)
#   - If `dry_run` is true the script will list groups to be deleted, but it won't delete them

# Required environment variables: GITLAB_QA_ACCESS_TOKEN, GITLAB_ADDRESS
# Optional environment variables: DELETE_BEFORE
#   - Set DELETE_BEFORE to delete only groups that were created before the given date (default: 1 day ago)

# Run `rake delete_user_groups`

module QA
  module Tools
    class DeleteUserGroups < DeleteResourceBase
      EXCLUDE_GROUPS = %w[gitlab-e2e-sandbox-group-1
        gitlab-e2e-sandbox-group-2
        gitlab-e2e-sandbox-group-3
        gitlab-e2e-sandbox-group-4
        gitlab-e2e-sandbox-group-5
        gitlab-e2e-sandbox-group-6
        gitlab-e2e-sandbox-group-7
        quality-e2e-tests
        quality-e2e-tests-2
        quality-e2e-tests-3
        quality-e2e-tests-4
        quality-e2e-tests-5
        gitlab-migration-large-import-test
        gitlab-qa-product-analytics
        gitlab-qa-product-analytics-2
        qa-perf-testing
        remote-development].freeze

      # @example - delete user groups older than 1 day
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   bundle exec rake delete_user_groups
      #
      # @example - delete all user groups older than 2019-01-01
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   DELETE_BEFORE=2019-01-01 \
      #   bundle exec rake delete_user_groups
      #
      # @example - dry run
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   bundle exec rake "delete_user_groups[true]"
      def initialize(dry_run: false, exclude_groups: nil)
        super(dry_run: dry_run)

        @type = 'group'
        @exclude_groups = Array(exclude_groups.to_s.split(',')) + EXCLUDE_GROUPS
        @permanently_delete = false # this option is only available for subgroups
      end

      def run
        user_id, user_name = fetch_token_user_info
        logger.info("Running group delete for user #{user_name} (#{user_id}) on #{ENV['GITLAB_ADDRESS']}...")

        groups = fetch_user_groups
        results = delete_user_groups(groups)

        log_results(results)
      end

      private

      def delete_user_groups(groups)
        if @dry_run
          log_dry_run_output(groups)
          return
        end

        if groups.empty?
          logger.info("No groups found\n")
          return
        end

        delete_resources(groups)
      end

      def fetch_user_groups
        groups = fetch_resources("groups?owned=true&top_level_only=true")

        groups.select do |group|
          group[:marked_for_deletion_on].nil? \
          && @exclude_groups.exclude?(group[:path])
        end
      end

      def fetch_token_user_info
        logger.info("Fetching GITLAB_QA_ACCESS_TOKEN user ...")

        user_response = get Runtime::API::Request.new(@api_client, "/user").url

        unless user_response.code == HTTP_STATUS_OK
          logger.error("Request for user returned (#{user_response.code}): `#{user_response}` ")
          exit 1 if fatal_response?(user_response.code)
          return
        end

        parsed_response = parse_body(user_response)

        if parsed_response.empty?
          logger.error("User not found")
          exit 1
        end

        [parsed_response[:id], parsed_response[:username]]
      rescue StandardError => e
        logger.error("Failed to fetch user for GITLAB_QA_ACCESS_TOKEN: #{e.message}")
        exit 1
      end

      def resource_request(group, **options)
        Runtime::API::Request.new(@api_client, "/groups/#{group[:id]}", **options).url
      end
    end
  end
end
