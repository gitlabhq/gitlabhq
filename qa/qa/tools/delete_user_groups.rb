# frozen_string_literal: true

# This script deletes top level groups owned by the user who owns the GITLAB_QA_ACCESS_TOKEN (gitlab-qa)
#   - If `dry_run` is true the script will list groups to be deleted, but it won't delete them

# Required environment variables: GITLAB_QA_ACCESS_TOKEN, GITLAB_ADDRESS
# Optional environment variables: DELETE_BEFORE - YYYY-MM-DD, YYYY-MM-DD HH:MM:SS, or YYYY-MM-DDT00:00:00Z
#   - Set DELETE_BEFORE to delete only groups that were created before the given date (default: 24 hours ago)

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
        gitlab-e2e-sandbox-group-8
        quality-e2e-tests
        quality-e2e-tests-2
        quality-e2e-tests-3
        quality-e2e-tests-4
        quality-e2e-tests-5
        appsec-test-group
        compliance-test
        gitlab-migration-large-import-test
        gitlab-qa-product-analytics
        gitlab-qa-product-analytics-2
        import-export-testing-group
        qa-perf-testing
        remote-development
        saml-sso-group
        test-custom-roles].freeze

      # @example - delete user groups older than 24 hours
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
        results = USER_TOKENS.flat_map do |token_name|
          next unless ENV[token_name]

          @user_api_client = user_api_client(ENV[token_name])
          user = fetch_token_user(token_name, @user_api_client)
          next if user[:id].nil?

          logger.info("Running group delete for user #{user[:username]} (#{user[:id]}) on #{ENV['GITLAB_ADDRESS']}...")

          groups = fetch_user_groups
          results = delete_user_groups(groups)
        end.compact

        log_results(results, @dry_run)
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
        groups = fetch_resources("groups?owned=true&top_level_only=true", @user_api_client)

        groups.select do |group|
          # sandbox groups can't be deleted immediately so ignore ones already marked for deletion
          group[:marked_for_deletion_on].nil? &&
            @exclude_groups.exclude?(group[:path])
        end
      end

      def resource_request(group, **options)
        Runtime::API::Request.new(@user_api_client, "/groups/#{group[:id]}", **options).url
      end
    end
  end
end
