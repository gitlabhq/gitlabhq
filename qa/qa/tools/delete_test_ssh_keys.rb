# frozen_string_literal: true

require_relative '../../qa'

# This script deletes all selected test ssh keys for a specific user
# Keys can be selected by a string matching part of the key's title and by created date
#   - Specify `title_portion` to delete only keys that include the string provided
#   - Specify `delete_before` to delete only keys that were created before the given date
#
# If `dry_run` is true the script will list the keys by title and indicate whether each will be deleted
#
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
#   - GITLAB_QA_ACCESS_TOKEN should have API access and belong to the user whose keys will be deleted

module QA
  module Tools
    class DeleteTestSSHKeys
      include Support::Api

      ITEMS_PER_PAGE = '100'

      def initialize(title_portion: 'E2E test key:', delete_before: Date.today.to_s, dry_run: false)
        raise ArgumentError, "Please provide GITLAB_ADDRESS" unless ENV['GITLAB_ADDRESS']
        raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN" unless ENV['GITLAB_QA_ACCESS_TOKEN']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
        @title_portion = title_portion
        @delete_before = Date.parse(delete_before)
        @dry_run = dry_run
      end

      def run
        $stdout.puts 'Running...'

        keys_head_response = head Runtime::API::Request.new(@api_client, "/user/keys", per_page: ITEMS_PER_PAGE).url
        total_pages = keys_head_response.headers[:x_total_pages]

        test_ssh_key_ids = fetch_test_ssh_key_ids(total_pages)
        $stdout.puts "Number of test ssh keys to be deleted: #{test_ssh_key_ids.length}"

        return if dry_run?

        delete_ssh_keys(test_ssh_key_ids) unless test_ssh_key_ids.empty?
        $stdout.puts "\nDone"
      end

      private

      attr_reader :dry_run
      alias_method :dry_run?, :dry_run

      def delete_ssh_keys(ssh_key_ids)
        $stdout.puts "Deleting #{ssh_key_ids.length} ssh keys..."
        ssh_key_ids.each do |key_id|
          delete_response = delete Runtime::API::Request.new(@api_client, "/user/keys/#{key_id}").url
          dot_or_f = delete_response.code == 204 ? "\e[32m.\e[0m" : "\e[31mF\e[0m"
          print dot_or_f
        end
      end

      def fetch_test_ssh_key_ids(pages)
        key_ids = []

        pages.to_i.times do |page_no|
          get_keys_response = get Runtime::API::Request.new(@api_client, "/user/keys", page: (page_no + 1).to_s, per_page: ITEMS_PER_PAGE).url
          keys = JSON.parse(get_keys_response.body).select do |key|
            to_delete = key['title'].include?(@title_portion) && Date.parse(key['created_at']) < @delete_before

            puts "Key title: #{key['title']}\tcreated_at: #{key['created_at']}\tdelete? #{to_delete}" if dry_run?

            to_delete
          end
          key_ids.concat(keys.map { |key| key['id'] })
        end

        key_ids.uniq
      end
    end
  end
end
