# frozen_string_literal: true

# This script deletes all projects owned by a given USER_ID or QA_USERNAMES in their personal namespace
# Required environment variables: GITLAB_QA_ACCESS_TOKEN, GITLAB_ADDRESS, and USER_ID or CLEANUP_ALL_QA_USER_PROJECTS
# Run `rake delete_user_projects`

module QA
  module Tools
    class DeleteUserProjects
      include Support::API
      include Lib::Project
      include Ci::Helpers

      # We cannot pass ids because they are different on each live environment
      QA_USERNAMES = %w[gitlab-qa
        gitlab-qa-admin
        gitlab-qa-user1
        gitlab-qa-user2
        gitlab-qa-user3
        gitlab-qa-user4
        gitlab-qa-user5
        gitlab-qa-user6].freeze

      def initialize(delete_before: (Date.today - 3).to_s, dry_run: false)
        %w[GITLAB_ADDRESS GITLAB_QA_ACCESS_TOKEN].each do |var|
          raise ArgumentError, "Please provide #{var} environment variable" unless ENV[var]
        end

        unless ENV['USER_ID'] || ENV['CLEANUP_ALL_QA_USER_PROJECTS']
          raise ArgumentError, "Please provide USER_ID or CLEANUP_ALL_QA_USER_PROJECTS environment variable"
        end

        @delete_before = Date.parse(delete_before)
        @dry_run = dry_run
        @api_client = set_api_client(ENV['GITLAB_QA_ACCESS_TOKEN'])
      end

      # @example
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   USER_ID=<id> bundle exec rake "delete_user_projects[2023-01-01,true]"
      #
      # @example
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   USER_ID=<id> bundle exec rake "delete_user_projects[,true]"
      #
      # @example
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   CLEANUP_ALL_QA_USER_PROJECTS=true bundle exec rake delete_user_projects
      def run
        user_ids = fetch_user_ids
        return 'No users found. Skipping project delete.' if user_ids.empty?

        user_ids.each do |user_id|
          qa_username = fetch_qa_username(user_id)

          api_client = if qa_username == "gitlab-qa-user1" && ENV['GITLAB_QA_USER1_ACCESS_TOKEN']
                         set_api_client(ENV['GITLAB_QA_USER1_ACCESS_TOKEN'])
                       elsif qa_username == "gitlab-qa-user2" && ENV['GITLAB_QA_USER2_ACCESS_TOKEN']
                         set_api_client(ENV['GITLAB_QA_USER2_ACCESS_TOKEN'])
                       else
                         @api_client
                       end

          delete_user_projects(qa_username, user_id, api_client)
        end
      end

      private

      def delete_user_projects(qa_username, user_id, api_client)
        logger.info("Running project delete for user #{qa_username} (#{user_id}) on #{ENV['GITLAB_ADDRESS']}...")

        projects_head_response = head Runtime::API::Request.new(api_client, "/users/#{user_id}/projects",
          per_page: "100").url
        total_project_pages = projects_head_response.headers[:x_total_pages]
        total_projects = projects_head_response.headers[:x_total]

        logger.info("Total projects: #{total_projects}")
        return logger.info("\nDone") if total_projects.to_i == 0

        project_ids = fetch_project_ids(total_project_pages, user_id)
        logger.info("Total projects created before #{@delete_before}: #{project_ids.size}")

        delete_projects(project_ids, api_client, @dry_run) unless project_ids.empty?
        logger.info("\nDone")
      end

      def fetch_project_ids(total_project_pages, user_id)
        projects_ids = []

        total_project_pages.to_i.times do |page_no|
          projects_response = get Runtime::API::Request.new(@api_client, "/users/#{user_id}/projects",
            page: (page_no + 1).to_s, per_page: "100").url
          projects_ids.concat(JSON.parse(projects_response.body)
                                  .select { |project| Date.parse(project["created_at"]) < @delete_before }
                                  .map { |project| project["id"] })
        rescue StandardError => e
          logger.error("Failed to fetch projects for user #{user_id}: #{e.message}")
        end

        projects_ids.uniq
      end

      def fetch_user_ids
        user_ids = ENV['CLEANUP_ALL_QA_USER_PROJECTS'] ? fetch_qa_user_ids : []
        user_ids << ENV['USER_ID'].to_i if ENV['USER_ID']

        user_ids.uniq
      end

      def fetch_qa_user_ids
        logger.info("Fetching QA user ids...")
        user_ids = []

        QA_USERNAMES.each do |qa_username|
          user_response = get Runtime::API::Request.new(@api_client, "/users", username: qa_username).url

          unless user_response.code == HTTP_STATUS_OK
            logger.error("Request for #{qa_username} returned (#{user_response.code}): `#{user_response}` ")
            next
          end

          parsed_response = JSON.parse(user_response.body)

          if parsed_response.empty?
            logger.error("User #{qa_username} not found")
            next
          end

          user_ids << parsed_response.first["id"]
        rescue StandardError => e
          logger.error("Failed to fetch user ID for #{qa_username}: #{e.message}")
        end

        user_ids.uniq
      end

      def fetch_qa_username(user_id)
        response = get Runtime::API::Request.new(@api_client, "/users/#{user_id}").url
        parsed_response = JSON.parse(response.body)
        parsed_response["username"]
      end

      def set_api_client(token)
        Runtime::API::Client.new(ENV['GITLAB_ADDRESS'],
          personal_access_token: token)
      end
    end
  end
end
