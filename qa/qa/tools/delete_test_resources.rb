# frozen_string_literal: true

# This script reads from test-resources JSON file to collect data about resources to delete
# Filter out resources that cannot be deleted
# Then deletes all deletable resources that E2E tests created
#
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# When in CI also requires: QA_TEST_RESOURCES_FILE_PATTERN
# Run `rake delete_test_resources[<file_pattern>]`

module QA
  module Tools
    class DeleteTestResources
      include Support::API

      IGNORED_RESOURCES = [
        'QA::Resource::PersonalAccessToken',
        'QA::Resource::CiVariable',
        'QA::Resource::Repository::Commit',
        'QA::EE::Resource::GroupIteration',
        'QA::EE::Resource::Settings::Elasticsearch'
      ].freeze

      def initialize(file_pattern = Runtime::Env.test_resources_created_filepath)
        raise ArgumentError, "Please provide GITLAB_ADDRESS" unless ENV['GITLAB_ADDRESS']
        raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN" unless ENV['GITLAB_QA_ACCESS_TOKEN']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
        @file_pattern = file_pattern
      end

      def run
        failures = files.flat_map do |file|
          resources = read_file(file)
          next if resources.nil?

          filtered_resources = filter_resources(resources)
          delete_resources(filtered_resources)
        end

        return puts "\nDone" if failures.empty?

        puts "\nFailed to delete #{failures.size} resources:\n"
        puts failures
      end

      private

      def files
        Runtime::Logger.info('Gathering JSON files...')
        files = Dir.glob(@file_pattern)
        abort("There is no file with this pattern #{@file_pattern}") if files.empty?

        files.reject! { |file| File.zero?(file) }

        files
      end

      def read_file(file)
        JSON.parse(File.read(file))
      rescue JSON::ParserError
        Runtime::Logger.error("Failed to read #{file} - Invalid format")
        nil
      end

      def filter_resources(resources)
        Runtime::Logger.info('Filtering resources - Only keep deletable resources...')

        transformed_values = resources.transform_values! do |v|
          v.reject do |attributes|
            attributes['info'] == "with full_path 'gitlab-qa-sandbox-group'" ||
              attributes['http_method'] == 'get' && !attributes['info']&.include?("with username 'qa-") ||
              attributes['api_path'] == 'Cannot find resource API path'
          end
        end

        transformed_values.reject! { |k, v| v.empty? || IGNORED_RESOURCES.include?(k) }
      end

      def delete_resources(resources)
        Runtime::Logger.info('Nothing to delete.') && return if resources.nil?

        resources.each_with_object([]) do |(key, value), failures|
          value.each do |resource|
            next if resource_not_found?(resource['api_path'])

            resource_info = resource['info'] ? "#{key} - #{resource['info']}" : "#{key} at #{resource['api_path']}"
            delete_response = delete(Runtime::API::Request.new(@api_client, resource['api_path']).url)

            if delete_response.code == 202 || delete_response.code == 204
              Runtime::Logger.info("Deleting #{resource_info}... SUCCESS")
            else
              Runtime::Logger.info("Deleting #{resource_info}... FAILED")
              failures << resource_info
            end
          end
        end
      end

      def resource_not_found?(api_path)
        # if api path contains param "?hard_delete=<boolean>", remove it
        get(Runtime::API::Request.new(@api_client, api_path.split('?').first).url).code.eql? 404
      end
    end
  end
end
