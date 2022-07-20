# frozen_string_literal: true

require "fog/google"

# This script handles resources created during E2E test runs
#
# Delete: find all matching file pattern, read file and delete resources
# rake test_resources:delete[<file_pattern>]
#
# Upload: find all matching file pattern for failed test resources
# upload these files to GCS bucket `failed-test-resources` under specific environment name
# rake test_resources:upload[<file_pattern>,<ci_project_name>]
#
# Download: download JSON files under a given environment name (bucket directory)
# save to local under `tmp/`
# rake test_resources:download[<ci_project_name>]
#
# Required environment variables:
#   GITLAB_ADDRESS, required for delete task
#   GITLAB_QA_ACCESS_TOKEN, required for delete task
#   QA_TEST_RESOURCES_FILE_PATTERN, optional for delete task, required for upload task
#   QA_FAILED_TEST_RESOURCES_GCS_CREDENTIALS, required for upload task or download task

module QA
  module Tools
    class TestResourcesHandler
      include Support::API

      IGNORED_RESOURCES = [
        'QA::Resource::PersonalAccessToken',
        'QA::Resource::CiVariable',
        'QA::Resource::Repository::Commit',
        'QA::EE::Resource::GroupIteration',
        'QA::EE::Resource::Settings::Elasticsearch',
        'QA::EE::Resource::VulnerabilityItem'
      ].freeze

      PROJECT = 'gitlab-qa-resources'
      BUCKET  = 'failed-test-resources'

      def initialize(file_pattern = nil)
        @file_pattern = file_pattern
      end

      def run_delete
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

      # Upload resources from failed test suites to GCS bucket
      # Files are organized by environment in which tests were executed
      #
      # E.g: staging/failed-test-resources-<randomhex>.json
      def upload(ci_project_name)
        if files.empty?
          puts "\nNothing to upload!"
          exit 0
        end

        files.each do |file|
          file_name = "#{ci_project_name}/#{file.split('/').last}"
          Runtime::Logger.info("Uploading #{file_name}...")
          gcs_storage.put_object(BUCKET, file_name, File.read(file))
        end

        puts "\nDone"
      end

      # Download files from GCS bucket by environment name
      # Delete the files afterward
      def download(ci_project_name)
        bucket_items = gcs_storage.list_objects(BUCKET, prefix: ci_project_name).items

        files_list = bucket_items&.each_with_object([]) do |obj, arr|
          arr << obj.name
        end

        if files_list.blank?
          puts "\nNothing to download!"
          exit 0
        end

        FileUtils.mkdir_p('tmp/')

        files_list.each do |file_name|
          local_path = "tmp/#{file_name.split('/').last}"
          Runtime::Logger.info("Downloading #{file_name} to #{local_path}")
          file = gcs_storage.get_object(BUCKET, file_name)
          File.write(local_path, file[:body])

          Runtime::Logger.info("Deleting #{file_name} from bucket")
          gcs_storage.delete_object(BUCKET, file_name)
        end

        puts "\nDone"
      end

      private

      def files
        Runtime::Logger.info('Gathering JSON files...')
        files = Dir.glob(@file_pattern)

        if files.empty?
          puts "There is no file with this pattern #{@file_pattern}"
          exit 0
        end

        files.reject! { |file| File.zero?(file) }

        if files.empty?
          puts "\nAll files were empty and rejected, nothing more to do!"
          exit 0
        end

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
            attributes['info']&.match(/with full_path 'gitlab-qa-sandbox-group(-\d)?'/) ||
              attributes['http_method'] == 'get' && !attributes['info']&.include?("with username 'qa-") ||
              attributes['api_path'] == 'Cannot find resource API path'
          end
        end

        transformed_values.reject! { |k, v| v.empty? || IGNORED_RESOURCES.include?(k) }
      end

      def delete_resources(resources)
        if resources.nil?
          puts "\nNo resources left to delete after filtering!"
          exit 0
        end

        resources.each_with_object([]) do |(key, value), failures|
          value.each do |resource|
            next if resource_not_found?(resource['api_path'])

            resource_info = resource['info'] ? "#{key} - #{resource['info']}" : "#{key} at #{resource['api_path']}"
            delete_response = delete(Runtime::API::Request.new(api_client, resource['api_path']).url)

            if delete_response.code == 202 || delete_response.code == 204
              Runtime::Logger.info("Deleting #{resource_info}... SUCCESS")
            else
              Runtime::Logger.info("Deleting #{resource_info}... FAILED - #{delete_response}")
              failures << resource_info
            end
          end
        end
      end

      def resource_not_found?(api_path)
        # if api path contains param "?hard_delete=<boolean>", remove it
        get(Runtime::API::Request.new(api_client, api_path.split('?').first).url).code.eql? 404
      end

      def api_client
        abort("\nPlease provide GITLAB_ADDRESS") unless ENV['GITLAB_ADDRESS']
        abort("\nPlease provide GITLAB_QA_ACCESS_TOKEN") unless ENV['GITLAB_QA_ACCESS_TOKEN']

        @api_client ||= Runtime::API::Client.new(
          ENV['GITLAB_ADDRESS'],
          personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN']
        )
      end

      def gcs_storage
        @gcs_storage ||= Fog::Storage::Google.new(
          google_project: PROJECT,
          **(File.exist?(json_key) ? { google_json_key_location: json_key } : { google_json_key_string: json_key })
        )
      rescue StandardError => e
        abort("\nThere might be something wrong with the JSON key file - [ERROR] #{e}")
      end

      # Path to GCS service account json key file
      # Or the content of the key file as a hash
      def json_key
        unless ENV['QA_FAILED_TEST_RESOURCES_GCS_CREDENTIALS']
          abort("\nPlease provide QA_FAILED_TEST_RESOURCES_GCS_CREDENTIALS")
        end

        @json_key ||= ENV["QA_FAILED_TEST_RESOURCES_GCS_CREDENTIALS"]
      end
    end
  end
end
