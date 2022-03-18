# frozen_string_literal: true

# This script deletes users with a username starting with "qa-user-"
#   - Specify `delete_before` to delete only keys that were created before the given date (default: yesterday)
#   - If `dry_run` is true the script will list the users to be deleted by username, but it won't delete them
#   - Specify `exclude_users` as a comma-separated list of usernames to not delete.
#
# Required environment variables: GITLAB_QA_ADMIN_ACCESS_TOKEN and GITLAB_ADDRESS
#   - GITLAB_QA_ADMIN_ACCESS_TOKEN must have admin API access

module QA
  module Tools
    class DeleteTestUsers
      include Support::API

      ITEMS_PER_PAGE = '100'
      EXCLUDE_USERS = %w[qa-user-abc123].freeze
      FALSY_VALUES = %w[false no 0].freeze

      def initialize(delete_before: (Date.today - 1).to_s, dry_run: 'false', exclude_users: nil)
        raise ArgumentError, "Please provide GITLAB_ADDRESS" unless ENV['GITLAB_ADDRESS']
        raise ArgumentError, "Please provide GITLAB_QA_ADMIN_ACCESS_TOKEN" unless ENV['GITLAB_QA_ADMIN_ACCESS_TOKEN']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: ENV['GITLAB_QA_ADMIN_ACCESS_TOKEN'])
        @dry_run = !FALSY_VALUES.include?(dry_run.to_s.downcase)
        @delete_before = Date.parse(delete_before)
        @page_no = '1'
        @exclude_users = Array(exclude_users.to_s.split(',')) + EXCLUDE_USERS
      end

      def run
        puts "Deleting users with a username starting with 'qa-user-' or 'test-user-' created before #{@delete_before}..."

        while page_no.present?
          users = fetch_test_users

          delete_test_users(users) if users.present?
        end

        puts "\nDone"
      end

      private

      attr_reader :dry_run, :page_no
      alias_method :dry_run?, :dry_run

      def fetch_test_users
        puts "Fetching QA test users from page #{page_no}..."

        response = get Runtime::API::Request.new(@api_client, "/users", page: page_no, per_page: ITEMS_PER_PAGE).url

        # When we reach the last page, the x-next-page header is a blank string
        @page_no = response.headers[:x_next_page].to_s

        if @page_no.to_i > 1000
          puts "Finishing early to avoid timing out the CI job"
          exit
        end

        JSON.parse(response.body).select do |user|
          user['username'].start_with?('qa-user-', 'test-user-') \
            && (user['name'] == 'QA Tests' || user['name'].start_with?('QA User')) \
            && !@exclude_users.include?(user['username']) \
            && Date.parse(user.fetch('created_at', Date.today.to_s)) < @delete_before
        end
      end

      def delete_test_users(users)
        usernames = users.map { |user| user['username'] }.join(', ')
        if dry_run?
          puts "Dry run: found users with usernames #{usernames}"

          return
        end

        puts "Deleting #{users.length} users with usernames #{usernames}..."
        users.each do |user|
          delete_response = delete Runtime::API::Request.new(@api_client, "/users/#{user['id']}", hard_delete: 'true').url
          dot_or_f = delete_response.code == 204 ? "\e[32m.\e[0m" : "\e[31mF\e[0m"
          print dot_or_f
        end
        print "\n"
      end
    end
  end
end
