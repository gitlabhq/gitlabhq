# frozen_string_literal: true

# This script deletes personal snippets for a specific user
#   - If `dry_run` is true the script will list snippets to be deleted, but it won't delete them

# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
#   - GITLAB_QA_ACCESS_TOKEN should have API access and belong to the user whose snippets will be deleted

# Optional environment variables: DELETE_BEFORE - YYYY-MM-DD, YYYY-MM-DD HH:MM:SS, or YYYY-MM-DDT00:00:00Z
#   - Set DELETE_BEFORE to only delete snippets that were created before a given date, otherwise default is 24 hours ago

# Run `rake delete_test_snippets`

module QA
  module Tools
    class DeleteTestSnippets < DeleteResourceBase
      # @example delete snippets older than 24 hours for the user associated with the given access token
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> bundle exec rake delete_test_snippets
      #
      # @example delete snippets older than 2023-01-01 for the user associated with the given access token
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   DELETE_BEFORE=2023-01-01 bundle exec rake delete_test_snippets
      #
      # @example - dry run
      #   GITLAB_ADDRESS=<address> \
      #   GITLAB_QA_ACCESS_TOKEN=<token> \
      #   DELETE_BEFORE=2023-01-01 bundle exec rake "delete_test_snippets[true]"
      def initialize(dry_run: false)
        super

        @type = 'snippet'
      end

      def run
        results = USER_TOKENS.flat_map do |token_name|
          next unless ENV[token_name]

          @user_api_client = user_api_client(ENV[token_name])
          user = fetch_token_user(token_name, @user_api_client)
          next if user[:id].nil?

          logger.info("Running snippet delete for user #{user[:username]} (#{user[:id]}) on #{ENV['GITLAB_ADDRESS']}..")

          snippets = fetch_resources("/snippets", @user_api_client)
          results = delete_snippets(snippets)
        end.compact

        log_results(results, @dry_run)
      end

      private

      def delete_snippets(snippets)
        if @dry_run
          log_dry_run_output(snippets)
          return
        end

        if snippets.empty?
          logger.info("No snippets found\n")
          return
        end

        delete_resources(snippets)
      end

      def resource_request(snippet, **options)
        Runtime::API::Request.new(@user_api_client, "/snippets/#{snippet[:id]}", **options).url
      end
    end
  end
end
