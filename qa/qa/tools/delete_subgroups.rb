# frozen_string_literal: true

# This script deletes all subgroups of a group specified by ENV['TOP_LEVEL_GROUP_NAME']
#   - If `dry_run` is true the script will list groups to be deleted, but it won't delete them

# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS

# Optional environment variables: TOP_LEVEL_GROUP_NAME (default: 'gitlab-qa-sandbox-group-<current weekday #>'),
#                                 CLEANUP_ALL_QA_SANDBOX_GROUPS (default: false),
#                                 PERMANENTLY_DELETE (default: false),
#                                 DELETE_BEFORE (default: 1 day ago)
# - Set TOP_LEVEL_GROUP_NAME to override the default group name determination logic.
#   If not set, the default group name will be:
#   - All 'gitlab-qa-sandbox-group-*' groups when CLEANUP_ALL_QA_SANDBOX_GROUPS is true
#   - 'gitlab-qa-sandbox-group-<current weekday #>' when CLEANUP_ALL_QA_SANDBOX_GROUPS is false
# - Set PERMANENTLY_DELETE to true if you would like to permanently delete subgroups on an environment with
#   deletion protection enabled. Otherwise, subgroups will remain available during the retention period specified
#   in admin settings. On environments with deletion protection disabled, subgroups will always be permanently deleted.
# - Set DELETE_BEFORE to only delete snippets that were created before a given date, otherwise defaults to 1 day ago

# Run `rake delete_subgroups`

module QA
  module Tools
    class DeleteSubgroups < DeleteResourceBase
      # @example mark subgroups for deletion that are older than 1 day under 'gitlab-qa-sandbox-group-<current weekday #>'
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> bundle exec rake delete_subgroups
      #
      # @examplem permanently delete subgroups older than 1 day under all gitlab-qa-sandbox-group-* groups
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   CLEANUP_ALL_QA_SANDBOX_GROUPS=true \
      #   PERMANENTLY_DELETE=true bundle exec rake delete_subgroups
      #
      # @example mark subgroups for deletion under 'gitlab-qa-sandbox-group-2' created before 2023-01-01
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   TOP_LEVEL_GROUP_NAME=<gitlab-qa-sandbox-group-2> \
      #   DELETE_BEFORE=2023-01-01 bundle exec rake delete_subgroups
      #
      # @example - dry run
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> bundle exec rake "delete_subgroups[true]"
      def initialize(dry_run: false)
        super

        @type = 'subgroup'
      end

      def run
        if ENV['CLEANUP_ALL_QA_SANDBOX_GROUPS'] && !ENV['TOP_LEVEL_GROUP_NAME']
          results = SANDBOX_GROUPS.flat_map do |name|
            group_id = fetch_group_id(@api_client, name)
            delete_subgroups(group_id)
          end.compact
        else
          group_id = fetch_group_id(@api_client)
          results = delete_subgroups(group_id)
        end

        log_results(results)
      end

      private

      def delete_subgroups(group_id)
        return unless group_id

        subgroups = fetch_resources("/groups/#{group_id}/subgroups")

        if @dry_run
          log_dry_run_output(subgroups)
          return
        end

        if subgroups.empty?
          logger.info("No subgroups found\n")
          return
        end

        delete_resources(subgroups)
      end

      def resource_request(subgroup, **options)
        Runtime::API::Request.new(@api_client, "/groups/#{subgroup[:id]}", **options).url
      end

      def resource_exists?(subgroup)
        response = get(resource_request(subgroup))

        if response.code == HTTP_STATUS_NOT_FOUND
          logger.info("Subgroup #{subgroup[:full_path]} is no longer available\n")
          false
        else
          true
        end
      end
    end
  end
end
