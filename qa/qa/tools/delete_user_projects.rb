# frozen_string_literal: true

# This script deletes all projects owned by a given USER_ID or QA_USERNAMES in their personal namespace
#   - If `dry_run` is true the script will list projects to be deleted, but it won't delete them

# Required environment variables: GITLAB_QA_ACCESS_TOKEN, GITLAB_ADDRESS, and USER_ID or CLEANUP_ALL_QA_USER_PROJECTS
#   - CLEANUP_ALL_QA_USER_PROJECTS to true if you would like to delete user projects for all qa test users
#     OR
#   - USER_ID to the id of the user whose projects are to be deleted.

# Optional environment variables: DELETE_BEFORE
#   - Set DELETE_BEFORE to delete only projects that were created before the given date (default: 1 day ago)

# Run `rake delete_user_projects`

module QA
  module Tools
    class DeleteUserProjects < DeleteResourceBase
      # We cannot pass ids because they are different on each live environment
      QA_USERNAMES = %w[gitlab-qa
        gitlab-qa-admin
        gitlab-qa-user1
        gitlab-qa-user2
        gitlab-qa-user3
        gitlab-qa-user4
        gitlab-qa-user5
        gitlab-qa-user6].freeze

      # @example - delete the given users projects older than 3 days
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   USER_ID=<id> bundle exec rake delete_user_projects
      #
      # @example - delete all users projects older than 2019-01-01
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   DELETE_BEFORE=2019-01-01 \
      #   CLEANUP_ALL_QA_USER_PROJECTS=true bundle exec rake delete_user_projects
      #
      # @example - dry run
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   USER_ID=<id> bundle exec rake "delete_user_projects[true]"
      def initialize(dry_run: false)
        unless ENV['USER_ID'] || ENV['CLEANUP_ALL_QA_USER_PROJECTS']
          raise ArgumentError, "Please provide USER_ID or CLEANUP_ALL_QA_USER_PROJECTS environment variable"
        end

        super

        @type = 'project'
      end

      def run
        user_ids = fetch_user_ids
        return 'No users found. Skipping project delete.' if user_ids.empty?

        results = user_ids.flat_map do |user_id|
          qa_username = fetch_qa_username(user_id)

          logger.info("Running project delete for user #{qa_username} (#{user_id}) on #{ENV['GITLAB_ADDRESS']}...")

          @user_api_client = if qa_username == "gitlab-qa-user1" && ENV['GITLAB_QA_USER1_ACCESS_TOKEN']
                               user_api_client(ENV['GITLAB_QA_USER1_ACCESS_TOKEN'])
                             elsif qa_username == "gitlab-qa-user2" && ENV['GITLAB_QA_USER2_ACCESS_TOKEN']
                               user_api_client(ENV['GITLAB_QA_USER2_ACCESS_TOKEN'])
                             else
                               @api_client
                             end

          projects = fetch_resources("/users/#{user_id}/projects")
          delete_user_projects(projects)
        end.compact

        log_results(results)
      end

      private

      def delete_user_projects(projects)
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

      def fetch_user_ids
        user_ids = ENV['CLEANUP_ALL_QA_USER_PROJECTS'] ? fetch_qa_user_ids : []
        user_ids << ENV['USER_ID'].to_i if ENV['USER_ID']

        user_ids.uniq
      end

      def fetch_qa_user_ids
        logger.info("Fetching QA user ids...")
        user_ids = []

        QA_USERNAMES.each do |qa_username|
          user_ids << fetch_qa_user_id(qa_username)
        end

        user_ids.uniq.compact
      end

      def fetch_qa_username(user_id)
        response = get Runtime::API::Request.new(@api_client, "/users/#{user_id}").url
        exit 1 if response.code == HTTP_STATUS_UNAUTHORIZED
        parsed_response = parse_body(response)
        parsed_response[:username]
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

      def resource_request(project, **options)
        Runtime::API::Request.new(@user_api_client, "/projects/#{project[:id]}", **options).url
      end
    end
  end
end
