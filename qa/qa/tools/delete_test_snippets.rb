# frozen_string_literal: true

# This script deletes personal snippets for a specific user
#   - If `dry_run` is true the script will list snippets to be deleted, but it won't delete them

# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
#   - GITLAB_QA_ACCESS_TOKEN should have API access and belong to the user whose snippets will be deleted

# Optional environment variables: DELETE_BEFORE (default: 1 day ago)
#   - Set DELETE_BEFORE to only delete snippets that were created before a given date, otherwise defaults to 1 day ago

# Run `rake delete_test_snippets`

module QA
  module Tools
    class DeleteTestSnippets < DeleteResourceBase
      # @example delete snippets older than 1 day for the user associated with the given access token
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
        snippets = fetch_resources("/snippets")

        results = delete_snippets(snippets)

        log_results(results)
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
        Runtime::API::Request.new(@api_client, "/snippets/#{snippet[:id]}", **options).url
      end
    end
  end
end
