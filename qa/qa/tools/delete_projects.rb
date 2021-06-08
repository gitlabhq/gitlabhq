# frozen_string_literal: true

require_relative '../../qa'

# This script deletes all projects directly under a group specified by ENV['TOP_LEVEL_GROUP_NAME']
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# Optional environment variable: TOP_LEVEL_GROUP_NAME (defaults to 'gitlab-qa-sandbox-group')
# Run `rake delete_projects`

module QA
  module Tools
    class DeleteProjects
      include Support::Api

      def initialize
        raise ArgumentError, "Please provide GITLAB_ADDRESS environment variable" unless ENV['GITLAB_ADDRESS']
        raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN environment variable" unless ENV['GITLAB_QA_ACCESS_TOKEN']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
      end

      def run
        $stdout.puts 'Running...'

        # Fetch group's id
        group_id = fetch_group_id

        projects_head_response = head Runtime::API::Request.new(@api_client, "/groups/#{group_id}/projects", per_page: "100").url
        total_project_pages = projects_head_response.headers[:x_total_pages]

        # Do not delete projects that are less than 4 days old (for debugging purposes)
        project_ids = fetch_project_ids(group_id, total_project_pages)
        $stdout.puts "Number of projects to be deleted: #{project_ids.length}"

        delete_projects(project_ids) unless project_ids.empty?
        $stdout.puts "\nDone"
      end

      private

      def delete_projects(project_ids)
        $stdout.puts "Deleting #{project_ids.length} projects..."
        project_ids.each do |project_id|
          delete_response = delete Runtime::API::Request.new(@api_client, "/projects/#{project_id}").url
          dot_or_f = delete_response.code.between?(200, 300) ? "\e[32m.\e[0m" : "\e[31mF\e[0m"
          print dot_or_f
        end
      end

      def fetch_group_id
        group_name = ENV['TOP_LEVEL_GROUP_NAME'] || 'gitlab-qa-sandbox-group'
        group_search_response = get Runtime::API::Request.new(@api_client, "/groups/#{group_name}").url
        JSON.parse(group_search_response.body)["id"]
      end

      def fetch_project_ids(group_id, total_project_pages)
        projects_ids = []

        total_project_pages.to_i.times do |page_no|
          projects_response = get Runtime::API::Request.new(@api_client, "/groups/#{group_id}/projects", page: (page_no + 1).to_s, per_page: "100").url
          projects_ids.concat(JSON.parse(projects_response.body).select { |project| Date.parse(project["created_at"]) < Date.today - 3 }.map { |project| project["id"] })
        end

        projects_ids.uniq
      end
    end
  end
end
