# frozen_string_literal: true

# This script deletes all projects directly under a group specified by ENV['TOP_LEVEL_GROUP_NAME']
#   - If `dry_run` is true the script will list projects to be deleted, but it won't delete them

# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS

# Optional environment variables: TOP_LEVEL_GROUP_NAME (default: 'gitlab-qa-sandbox-group-<current weekday #>'),
#                                 CLEANUP_ALL_QA_SANDBOX_GROUPS (default: false),
#                                 PERMANENTLY_DELETE (default: false),
#                                 DELETE_BEFORE (default: 1 day ago)
# - Set TOP_LEVEL_GROUP_NAME to the name of the qa sandbox group that you would like to delete projects under.
# - Set CLEANUP_ALL_QA_SANDBOX_GROUPS to true if you would like to delete projects under all
# 'gitlab-qa-sandbox-group-*' groups. Otherwise, this will fall back to TOP_LEVEL_GROUP_NAME.
# - Set PERMANENTLY_DELETE to true if you would like to permanently delete subgroups on an environment with
# deletion protection enabled. Otherwise, subgroups will remain available during the retention period specified
# in admin settings. On environments with deletion protection disabled, subgroups will always be permanently deleted.
# - Set DELETE_BEFORE to only delete projects that were created before a given date, otherwise defaults to 1 day ago

# Run `rake delete_projects`

module QA
  module Tools
    class DeleteProjects < DeleteResourceBase
      # @example mark projects for deletion under 'gitlab-qa-sandbox-group-<current weekday #>' older than 1 day
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> bundle exec rake delete_projects
      #
      # @example permanently delete projects older than 1 day under all gitlab-qa-sandbox-group-* groups
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   CLEANUP_ALL_QA_SANDBOX_GROUPS=true \
      #   PERMANENTLY_DELETE=true bundle exec rake delete_projects
      #
      # @example mark projects for deletion under 'gitlab-qa-sandbox-group-2' created before 2023-01-01
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   TOP_LEVEL_GROUP_NAME=<gitlab-qa-sandbox-group-2> \
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
        if ENV['CLEANUP_ALL_QA_SANDBOX_GROUPS']
          results = SANDBOX_GROUPS.flat_map do |name|
            group_id = fetch_group_id(@api_client, name)
            delete_projects(group_id)
          end.compact
        else
          group_id = fetch_group_id(@api_client)
          results = delete_projects(group_id)
        end

        log_results(results)
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
        Runtime::API::Request.new(@api_client, "/projects/#{project[:id]}", **options).url
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
