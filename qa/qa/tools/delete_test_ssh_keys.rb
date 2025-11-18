# frozen_string_literal: true

# This script deletes all selected test ssh keys for a specific user
# Keys can be selected by a string matching part of the key's title and by created date
#   - Specify `title_portion` to delete only keys that include the string provided
#   - If `dry_run` is true the script will list the keys by title and indicate whether each will be deleted

# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
#   - GITLAB_QA_ACCESS_TOKEN should have API access and belong to the user whose keys will be deleted

# Optional environment variables: DELETE_BEFORE - YYYY-MM-DD, YYYY-MM-DD HH:MM:SS, or YYYY-MM-DDT00:00:00Z
#   - Set DELETE_BEFORE to only delete snippets that were created before a given date, otherwise default is 24 hours ago

# Run `rake delete_test_ssh_keys`

module QA
  module Tools
    class DeleteTestSshKeys < DeleteResourceBase
      def initialize(title_portion: 'E2E test key:', dry_run: false)
        super(dry_run: dry_run)
        @title_portion = title_portion
        @type = "ssh key"
      end

      def run
        results = USER_TOKENS.flat_map do |token_name|
          next unless ENV[token_name]

          @user_api_client = user_api_client(ENV[token_name])
          user = fetch_token_user(token_name, @user_api_client)
          next if user[:id].nil?

          logger.info("Running ssh key delete for user #{user[:username]} (#{user[:id]}) on #{ENV['GITLAB_ADDRESS']}..")

          ssh_keys = fetch_test_ssh_keys
          results = delete_ssh_keys(ssh_keys)
        end.compact

        log_results(results, @dry_run)
      end

      private

      def delete_ssh_keys(ssh_keys)
        if @dry_run
          log_dry_run_output(ssh_keys)
          return
        end

        if ssh_keys.empty?
          logger.info("No SSH keys found\n")
          return
        end

        delete_resources(ssh_keys)
      end

      def fetch_test_ssh_keys
        keys = fetch_resources("/user/keys", @user_api_client)

        keys.select do |key|
          key[:title].include?(@title_portion)
        end
      end

      def resource_request(key, **options)
        Runtime::API::Request.new(@user_api_client, "/user/keys/#{key[:id]}", **options).url
      end

      def resource_path(resource)
        resource[:title]
      end
    end
  end
end
