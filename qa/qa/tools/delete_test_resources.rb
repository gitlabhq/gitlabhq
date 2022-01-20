# frozen_string_literal: true

# This script reads from test_resources.txt file to collect data about resources to delete
# Deletes all deletable resources that E2E tests created
# Resource type: Sandbox, User, Fork and RSpec::Mocks::Double are not included
#
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# When in CI also requires: QA_TEST_RESOURCES_FILE_PATTERN
# Run `rake delete_test_resources[<file_pattern>]`

module QA
  module Tools
    class DeleteTestResources
      include Support::API

      def initialize(file_pattern = nil)
        raise ArgumentError, "Please provide GITLAB_ADDRESS" unless ENV['GITLAB_ADDRESS']
        raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN" unless ENV['GITLAB_QA_ACCESS_TOKEN']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
        @file_pattern = file_pattern
      end

      def run
        puts 'Deleting test created resources...'

        if Runtime::Env.running_in_ci?
          raise ArgumentError, 'Please provide QA_TEST_RESOURCES_FILE_PATTERN' unless ENV['QA_TEST_RESOURCES_FILE_PATTERN']

          Dir.glob(@file_pattern).each do |file|
            delete_resources(load_file(file))
          end
        else
          file = Runtime::Env.test_resources_created_filepath
          raise ArgumentError, "'#{file}' either does not exist or empty." if !File.exist?(file) || File.zero?(file)

          delete_resources(load_file(file))
        end

        puts "\nDone"
      end

      private

      def load_file(json)
        JSON.parse(File.read(json))
      end

      def delete_resources(resources)
        failures = []

        resources.each_key do |type|
          next if resources[type].empty?

          resources[type].each do |resource|
            next if resource_not_found?(resource['api_path'])

            msg = resource['info'] ? "#{type} - #{resource['info']}" : "#{type} at #{resource['api_path']}"

            puts "\nDeleting #{msg}..."
            delete_response = delete(Runtime::API::Request.new(@api_client, resource['api_path']).url)

            if delete_response.code == 202
              print "\e[32m.\e[0m"
            else
              print "\e[31mF\e[0m"
              failures << msg
            end
          end
        end

        unless failures.empty?
          puts "\nFailed to delete #{failures.length} resources:\n"
          puts failures
        end
      end

      def resource_not_found?(api_path)
        get_response = get Runtime::API::Request.new(@api_client, api_path).url

        get_response.code.eql? 404
      end
    end
  end
end
