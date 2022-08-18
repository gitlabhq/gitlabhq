# frozen_string_literal: true

# This script deletes all projects owned by a given USER_ID in their personal namespace
# Required environment variables: USER_ID, GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# Run `rake delete_user_projects`

module QA
  module Tools
    class DeleteUserProjects
      include Support::API
      include Lib::Project

      def initialize(delete_before: (Date.today - 1).to_s, dry_run: false)
        unless ENV['GITLAB_ADDRESS']
          raise ArgumentError, "Please provide GITLAB_ADDRESS environment variable"
        end

        unless ENV['GITLAB_QA_ACCESS_TOKEN']
          raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN environment variable"
        end

        unless ENV['USER_ID']
          raise ArgumentError, "Please provide USER_ID environment variable"
        end

        @delete_before = Date.parse(delete_before)
        @dry_run = dry_run
        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'],
          personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
      end

      def run
        $stdout.puts 'Running...'

        projects_head_response = head Runtime::API::Request.new(@api_client, "/users/#{ENV['USER_ID']}/projects",
          per_page: "100").url
        total_project_pages = projects_head_response.headers[:x_total_pages]

        $stdout.puts "Total project pages: #{total_project_pages}"

        project_ids = fetch_project_ids(total_project_pages)

        delete_projects(project_ids, @api_client, @dry_run) unless project_ids.empty?
        $stdout.puts "\nDone"
      end

      private

      def fetch_project_ids(total_project_pages)
        projects_ids = []

        total_project_pages.to_i.times do |page_no|
          projects_response = get Runtime::API::Request.new(@api_client, "/users/#{ENV['USER_ID']}/projects",
            page: (page_no + 1).to_s, per_page: "100").url
          projects_ids.concat(JSON.parse(projects_response.body)
                                  .select { |project| Date.parse(project["created_at"]) < @delete_before }
                                  .map { |project| project["id"] })
        end

        projects_ids.uniq
      end
    end
  end
end
