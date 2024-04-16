# frozen_string_literal: true

# This script deletes all projects directly under a group specified by ENV['TOP_LEVEL_GROUP_NAME']
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# Optional environment variable: TOP_LEVEL_GROUP_NAME (defaults to 'gitlab-qa-sandbox-group')

# Optional environment variable: CLEANUP_ALL_QA_SANDBOX_GROUPS (defaults to false)
# Set CLEANUP_ALL_QA_SANDBOX_GROUPS to true if you would like to delete projects under all
# 'gitlab-qa-sandbox-group-*' groups. Otherwise, this will fall back to TOP_LEVEL_GROUP_NAME.

# Run `rake delete_projects`

module QA
  module Tools
    class DeleteProjects < DeleteResourceBase
      def run
        logger.info("Running...")

        # Fetch group's id
        if ENV['CLEANUP_ALL_QA_SANDBOX_GROUPS']
          SANDBOX_GROUPS.each do |name|
            group_id = fetch_group_id(@api_client, name)
            delete_selected_projects(group_id)
          end

        else
          group_id = fetch_group_id(@api_client)
          delete_selected_projects(group_id)
        end
      end

      private

      def delete_selected_projects(group_id)
        return unless group_id

        logger.info("Fetching projects...")
        projects_head_response = head Runtime::API::Request.new(@api_client, "/groups/#{group_id}/projects", per_page: "100").url
        total_project_pages = projects_head_response.headers[:x_total_pages]

        project_ids = fetch_project_ids(group_id, total_project_pages)
        logger.info("Number of projects to be deleted: #{project_ids.length}")

        delete_projects(project_ids, @api_client) unless project_ids.empty?
        logger.info("\nDone")
      end

      def fetch_project_ids(group_id, total_project_pages)
        projects_ids = []

        total_project_pages.to_i.times do |page_no|
          projects_response = get Runtime::API::Request.new(@api_client, "/groups/#{group_id}/projects", page: (page_no + 1).to_s, per_page: "100").url
          # Do not delete projects that are less than 4 days old (for debugging purposes)
          projects_ids.concat(parse_body(projects_response).select { |project| Date.parse(project[:created_at]) < @delete_before }.pluck(:id))
        end

        projects_ids.uniq
      end
    end
  end
end
