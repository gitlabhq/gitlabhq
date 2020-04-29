# frozen_string_literal: true

require_relative '../../qa'

# This script deletes all test ssh keys (with titles including 'key for ssh tests' or 'key for audit event test') of a user specified by ENV['GITLAB_USERNAME']
# Required environment variables: GITLAB_QA_ACCESS_TOKEN, GITLAB_ADDRESS and GITLAB_USERNAME

module QA
  module Tools
    class DeleteTestSSHKeys
      include Support::Api

      def initialize
        raise ArgumentError, "Please provide GITLAB_ADDRESS" unless ENV['GITLAB_ADDRESS']
        raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN" unless ENV['GITLAB_QA_ACCESS_TOKEN']
        raise ArgumentError, "Please provide GITLAB_USERNAME" unless ENV['GITLAB_USERNAME']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
        @username = ENV['GITLAB_USERNAME']
      end

      def run
        STDOUT.puts 'Running...'

        user_id = fetch_user_id
        test_ssh_key_ids = fetch_test_ssh_key_ids(user_id)
        STDOUT.puts "Number of test ssh keys to be deleted: #{test_ssh_key_ids.length}"

        delete_ssh_keys(user_id, test_ssh_key_ids) unless test_ssh_key_ids.empty?
        STDOUT.puts "\nDone"
      end

      private

      def fetch_user_id
        get_user_response = get Runtime::API::Request.new(@api_client, "/users?username=#{@username}").url
        user = JSON.parse(get_user_response.body).first
        raise "Unexpected user found. Expected #{@username}, found #{user['username']}" unless user['username'] == @username

        user["id"]
      end

      def delete_ssh_keys(user_id, ssh_key_ids)
        STDOUT.puts "Deleting #{ssh_key_ids.length} ssh keys..."
        ssh_key_ids.each do |key_id|
          delete_response = delete Runtime::API::Request.new(@api_client, "/users/#{user_id}/keys/#{key_id}").url
          dot_or_f = delete_response.code == 204 ? "\e[32m.\e[0m" : "\e[31mF\e[0m"
          print dot_or_f
        end
      end

      def fetch_test_ssh_key_ids(user_id)
        get_keys_response = get Runtime::API::Request.new(@api_client, "/users/#{user_id}/keys").url
        JSON.parse(get_keys_response.body)
          .select { |key| (key["title"].include?('key for ssh tests') || key["title"].include?('key for audit event test')) }
          .map { |key| key['id'] }
          .uniq
      end
    end
  end
end
