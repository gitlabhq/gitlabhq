# frozen_string_literal: true

# This script deletes personal snippets for a specific user
#   - Specify `delete_before` to delete only snippets that were created before the given date (default: yesterday)
#   - If `dry_run` is true the script will list snippets to be deleted, but it won't delete them
#
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
#   - GITLAB_QA_ACCESS_TOKEN should have API access and belong to the user whose snippets will be deleted

module QA
  module Tools
    class DeleteTestSnippets
      include Support::API

      ITEMS_PER_PAGE = '1'

      def initialize(delete_before: (Date.today - 1).to_s, dry_run: false)
        raise ArgumentError, "Please provide GITLAB_ADDRESS" unless ENV['GITLAB_ADDRESS']
        raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN" unless ENV['GITLAB_QA_ACCESS_TOKEN']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'],
          personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
        @delete_before = Date.parse(delete_before)
        @dry_run = dry_run
      end

      def run
        $stdout.puts 'Running...'

        response = head Runtime::API::Request.new(@api_client, "/snippets", per_page: ITEMS_PER_PAGE).url
        total_pages = response.headers[:x_total_pages]

        test_snippet_ids = fetch_snippet_ids(total_pages)
        $stdout.puts "Number of test snippets to be deleted: #{test_snippet_ids.length}"

        return if dry_run?

        delete_snippets(test_snippet_ids) unless test_snippet_ids.empty?
        $stdout.puts "\nDone"
      end

      private

      attr_reader :dry_run
      alias_method :dry_run?, :dry_run

      def delete_snippets(snippet_ids)
        $stdout.puts "Deleting #{snippet_ids.length} snippet(s)..."
        snippet_ids.each do |snippet_id|
          delete_response = delete Runtime::API::Request.new(@api_client, "/snippets/#{snippet_id}").url
          dot_or_f = delete_response.code == 204 ? "\e[32m.\e[0m" : "\e[31mF\e[0m"
          print dot_or_f
        end
      end

      def fetch_snippet_ids(pages)
        snippet_ids = []

        pages.to_i.times do |page_no|
          get_snippet_response = get Runtime::API::Request.new(@api_client, "/snippets",
            page: (page_no + 1).to_s, per_page: ITEMS_PER_PAGE).url
          snippets = JSON.parse(get_snippet_response.body).select do |snippet|
            to_delete = Date.parse(snippet['created_at']) < @delete_before

            if dry_run?
              puts "Snippet title: #{snippet['title']}\tcreated_at: #{snippet['created_at']}\tdelete? #{to_delete}"
            end

            to_delete
          end
          snippet_ids.concat(snippets.map { |snippet| snippet['id'] })

          if (page_no + 1) == 1000
            puts "Stopping at page 1000 to avoid timeout, total number of pages: #{pages}"
            break
          end
        end

        snippet_ids.uniq
      end
    end
  end
end
