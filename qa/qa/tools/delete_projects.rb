# frozen_string_literal: true

# This script deletes all projects directly under all 'gitlab-e2e-sandbox-group-<#1-8>' groups OR a group specified by
# ENV['TOP_LEVEL_GROUP_NAME']
#   - If `dry_run` is true the script will list projects to be deleted, but it won't delete them

# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS

# Optional environment variables: TOP_LEVEL_GROUP_NAME,
#                                 PERMANENTLY_DELETE (default: false),
#                                 DELETE_BEFORE - YYYY-MM-DD, YYYY-MM-DD HH:MM:SS, or YYYY-MM-DDT00:00:00Z
#                                 SKIP_VERIFICATION (default: false)
# - Set TOP_LEVEL_GROUP_NAME to the name of the e2e sandbox group that you would like to delete projects under.
# Otherwise, this will fall back to deleting projects under all top level groups.
# - Set PERMANENTLY_DELETE to true if you would like to permanently delete subgroups on an environment with
# deletion protection enabled. Otherwise, subgroups will remain available during the retention period specified
# in admin settings. On environments with deletion protection disabled, subgroups will always be permanently deleted.
# - Set DELETE_BEFORE to only delete projects that were created before a given date, otherwise defaults to 24 hours ago
# - Set SKIP_VERIFICATION to true if you would like to skip the verification step for time constraint purposes.
#   This should only be used in specific circumstances such as cleaning up a large backlog of resources when deletions
#   are known to be working.

# Run `rake delete_projects`

module QA
  module Tools
    class DeleteProjects < DeleteResourceBase
      # @example mark projects for deletion that are older than 24 hours under gitlab-e2e-sandbox-group-<#1-8> groups
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> bundle exec rake delete_projects
      #
      # @example permanently delete projects older than 24 hours under all gitlab-e2e-sandbox-group-<#1-8> groups
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   PERMANENTLY_DELETE=true bundle exec rake delete_projects
      #
      # @example mark projects for deletion under 'gitlab-e2e-sandbox-group-2' created before 2023-01-01
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   TOP_LEVEL_GROUP_NAME=<gitlab-e2e-sandbox-group-2> \
      #   DELETE_BEFORE=2023-01-01 bundle exec rake delete_projects
      #
      # @example - dry run
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> bundle exec rake "delete_projects[true]"
      def initialize(dry_run: false)
        super

        @type = 'project'
      end

      def run
        if ENV['TOP_LEVEL_GROUP_NAME']
          group_id = fetch_group_id(api_client, ENV['TOP_LEVEL_GROUP_NAME'])
          results = delete_projects(group_id)
        else
          results = SANDBOX_GROUPS.flat_map do |name|
            group_id = fetch_group_id(api_client, name)
            delete_projects(group_id)
          end.compact
        end

        log_results(results, @dry_run)
      end

      private

      def delete_projects(group_id)
        return unless group_id

        projects = fetch_resources("/groups/#{group_id}/projects")

        if @dry_run
          log_dry_run_output(projects)
          return
        end

        if projects.empty?
          logger.info("No projects found\n")
          return
        end

        delete_resources(projects)
      end

      def resource_request(project, **options)
        Runtime::API::Request.new(api_client, "/projects/#{project[:id]}", **options).url
      end

      def resource_exists?(project)
        response = get(resource_request(project))

        if response.code == HTTP_STATUS_NOT_FOUND
          logger.info("Project #{project[:path_with_namespace]} is no longer available\n")
          false
        else
          true
        end
      end
    end
  end
end
