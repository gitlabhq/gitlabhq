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
      include Support::Waiter
      include Support::Repeater
      include Ci::Helpers
      include SharedResourceDeletion

      IGNORED_RESOURCES = %w[
        QA::Resource::Ci::RunnerManager
        QA::Resource::CICDSettings
        QA::Resource::CiVariable
        QA::Resource::Design
        QA::Resource::Fork
        QA::Resource::InstanceOauthApplication
        QA::Resource::PersonalAccessToken
        QA::Resource::Repository::Commit
        QA::Resource::UserGPG
        QA::EE::Resource::ComplianceFramework
        QA::EE::Resource::GroupIteration
        QA::EE::Resource::InstanceAuditEventExternalDestination
        QA::EE::Resource::ScanResultPolicyCommit
        QA::EE::Resource::ScanResultPolicyProject
        QA::EE::Resource::SecurityScanPolicyProject
        QA::EE::Resource::Settings::Elasticsearch
        QA::EE::Resource::VulnerabilityItem
      ].freeze

      PERSONAL_RESOURCES = %w[QA::Resource::Snippet].freeze

      PROJECT = 'gitlab-qa-resources'
      BUCKET  = 'failed-test-resources'

      def initialize(file_pattern = nil)
        @file_pattern = file_pattern
        # Default to true to keep the existing behavior when $PERMANENTLY_DELETE isn't set
        @permanently_delete = Gitlab::Utils.to_boolean(ENV['PERMANENTLY_DELETE'], default: true)
      end

      def run_delete
        results = files.flat_map do |file|
          resources = read_file(file)
          if resources.nil?
            logger.info("#{file} is empty, next...")
            next
          end

          filtered_resources = filter_resources(resources)
          if filtered_resources.nil?
            logger.info("No resources left to delete after filtering!")
            next
          end

          resource_list = organize_resources(filtered_resources)
          delete_resources(resource_list)
        end.compact

        log_results(results)
      end

      # Upload resources from failed test suites to GCS bucket
      # Files are organized by environment in which tests were executed
      #
      # E.g: staging/failed-test-resources-<randomhex>.json
      def upload(ci_project_name)
        if files.empty?
          logger.info("\nNothing to upload!")
          return
        end

        files.each do |file|
          file_name = "#{ci_project_name}/#{file.split('/').last}"
          logger.info("Uploading #{file_name}...")
          gcs_storage.put_object(BUCKET, file_name, File.read(file))
        end
      end

      # Download files from GCS bucket by environment name
      # Delete the files afterward
      def download(ci_project_name)
        logger.info("Downloading resource files from GCS for #{ci_project_name}...")
        bucket_items = gcs_storage.list_objects(BUCKET, prefix: "#{ci_project_name}/").items

        if bucket_items.blank?
          logger.info("\nNothing to download!")
          return
        end

        files_list = bucket_items.each_with_object([]) do |obj, arr|
          arr << obj.name
        end

        FileUtils.mkdir_p('tmp/')

        files_list.each do |file_name|
          local_path = "tmp/#{file_name.split('/').last}"
          logger.info("Downloading #{file_name} to #{local_path}")
          file = gcs_storage.get_object(BUCKET, file_name)
          File.write(local_path, file[:body])

          logger.info("Deleting #{file_name} from bucket")
          gcs_storage.delete_object(BUCKET, file_name)
        end
      end

      private

      # Returns a memoized GitLab API client instance
      #
      # Creates and caches a Runtime::API::Client configured with the GitLab instance
      # address and authentication token. The client is used for all API operations
      # including resource deletion, fetching, and GraphQL requests.
      #
      # @return [Runtime::API::Client] Configured API client instance
      # @raise [SystemExit] If GITLAB_ADDRESS environment variable is not set
      def api_client
        abort("\nPlease provide GITLAB_ADDRESS") unless ENV['GITLAB_ADDRESS']

        @api_client ||= Runtime::API::Client.new(
          ENV['GITLAB_ADDRESS'],
          personal_access_token: personal_access_token
        )
      end

      # Deletes a personal resource using the original author's credentials
      #
      # @param [Hash] resource The resource to delete, must contain [:author][:username]
      # @param [Boolean] delayed_verification Wait until the end of the script to verify deletion
      # @param [Boolean] permanent Permanently delete the resource instead of marking for deletion
      # @param [Boolean] skip_verification Skip verification of deletion for time constraint purposes
      # @return [Array<String, Hash>, Hash] Deletion result or resource for delayed verification
      def delete_personal_resource(resource, delayed_verification, permanent, skip_verification)
        username = resource[:author][:username]
        user_client = set_api_client_by_username(username)

        with_api_client(user_client) do
          delete_resource(resource, delayed_verification, permanent, skip_verification)
        end
      end

      # Deletes resources from a structured hash organized by resource type
      #
      # @param [Hash<String, Array<Hash>>] resources_hash Hash where keys are resource class names
      # @param [Boolean] delayed_verification Wait until the end of the script to verify deletions. Defaults to false
      # @param [Boolean] permanent Permanently delete resources instead of marking for deletion. Defaults to true
      # @param [Boolean] skip_verification Skip verification of deletion for time constraint purposes. Defaults to false
      # @return [Array<Array<String, Hash>>] Array of deletion results
      def delete_resources(
        resources_hash,
        delayed_verification = false,
        permanent = @permanently_delete,
        skip_verification = false)
        unverified_deletions = []
        results = []

        resources_hash.each do |(key, value)|
          type = key.split('::').last.downcase

          value.each do |resource_hash|
            next if resource_not_found?(resource_hash['api_path'])

            resource = get_resource(resource_hash['api_path'])
            next unless resource

            resource_info = resource_info(resource_hash, key)
            logger.info("Processing #{resource_info}...")

            resource[:api_path] = resource_hash['api_path']
            resource[:type] = type

            result = if personal_resource?(key)
                       delete_personal_resource(resource, delayed_verification, permanent, skip_verification)
                     elsif type == 'user'
                       delete_resource(resource, true, permanent, skip_verification)
                     else
                       delete_resource(resource, delayed_verification, permanent, skip_verification)
                     end

            if result.is_a?(Array)
              results.append(result)
            else
              unverified_deletions << result
            end
          end
        end

        results.concat(verify_deletions(unverified_deletions, permanent)) unless unverified_deletions.empty?

        results
      end

      # Gathers and validates JSON files matching the configured @file_pattern
      #
      # @return [Array<String>] Array of file paths that match the pattern and contain data
      # @raise [SystemExit] Exits with status 0 if no files match the pattern or all files are empty
      def files
        logger.info("Gathering JSON files using pattern #{@file_pattern}...")
        files = Dir.glob(@file_pattern)

        if files.empty?
          logger.info("There is no file with this pattern")
          exit 0
        else
          logger.info("Found #{files.size} JSON file(s) to process")
        end

        files.reject! { |file| File.zero?(file) }

        if files.empty?
          logger.info("\nAll files were empty and rejected, nothing more to do!")
          exit 0
        end

        files
      end

      # Filters resources to keep only those that are safe and appropriate for deletion
      #
      # Removes resources that match exclusion criteria to prevent accidental deletion
      # of protected or system resources. Filters out sandbox groups, non-deletable
      # GET requests, invalid API paths, GraphQL endpoints, and resource types listed
      # in IGNORED_RESOURCES constant.
      #
      # @param [Hash<String, Array<Hash>>] resources Hash where keys are resource class names
      #   and values are arrays of resource attribute hashes
      # @return [Hash<String, Array<Hash>>, nil] Filtered resources hash with unsafe resources
      #   removed, or nil if no deletable resources remain
      def filter_resources(resources)
        logger.info('Filtering resources - Only keep deletable resources...')

        transformed_values = resources.transform_values! do |v|
          v.reject do |attributes|
            # We don't want to delete sandbox groups
            attributes['info']&.match(/with full_path 'gitlab-e2e-sandbox-group(-\d)?'/) ||
              (attributes['http_method'] == 'get' && !attributes['info']&.include?("with username 'qa-")) ||
              attributes['api_path'] == 'Cannot find resource API path' ||
              attributes['api_path'] == '/graphql'
          end
        end

        transformed_values.reject! { |k, v| v.empty? || IGNORED_RESOURCES.include?(k) }
      end

      # Returns a memoized Google Cloud Storage client instance
      #
      # Creates and caches a Fog::Google::Storage client configured with the project
      # and authentication credentials. Automatically detects whether the json_key
      # is a file path (uses google_json_key_location) or a JSON string (uses
      # google_json_key_string) for authentication.
      #
      # @return [Fog::Google::Storage] Configured GCS client instance
      # @raise [SystemExit] Aborts program execution if JSON key file/string is invalid
      def gcs_storage
        @gcs_storage ||= Fog::Google::Storage.new(
          google_project: PROJECT,
          **(File.exist?(json_key) ? { google_json_key_location: json_key } : { google_json_key_string: json_key })
        )
      rescue StandardError => e
        abort("\nThere might be something wrong with the JSON key file - [ERROR] #{e}")
      end

      # Returns the GCS service account JSON key for authentication
      #
      # Retrieves and memoizes the Google Cloud Storage authentication credentials
      # from the QA_FAILED_TEST_RESOURCES_GCS_CREDENTIALS environment variable.
      # The value can be either a file path to a JSON key file or the JSON key
      # content as a string.
      #
      # @return [String] Either the file path to the JSON key file or the JSON key content as a string
      # @raise [SystemExit] Aborts program execution if QA_FAILED_TEST_RESOURCES_GCS_CREDENTIALS is not set
      def json_key
        unless ENV['QA_FAILED_TEST_RESOURCES_GCS_CREDENTIALS']
          abort("\nPlease provide QA_FAILED_TEST_RESOURCES_GCS_CREDENTIALS")
        end

        @json_key ||= ENV["QA_FAILED_TEST_RESOURCES_GCS_CREDENTIALS"]
      end

      # Organizes resources in hierarchical deletion order for efficient cleanup
      #
      # Reorders resources to respect dependency relationships during deletion.
      # The deletion order prevents dependency conflicts by removing parent resources
      # before child resources, and system resources before user resources.
      #
      # @param [Hash<String, Array<Hash>>] filtered_resources Hash where keys are resource
      #   class names and values are arrays of resource data hashes
      # @return [Hash<String, Array<Hash>>] Reorganized resources hash in deletion order:
      #   1. Sandboxes, 2. Groups, 3. Projects, 4. Other resources, 5. Users
      def organize_resources(filtered_resources)
        organized_resources = {}

        sandboxes = filtered_resources.delete('QA::Resource::Sandbox')
        groups = filtered_resources.delete('QA::Resource::Group')
        projects = filtered_resources.delete('QA::Resource::Project')
        users = filtered_resources.delete('QA::Resource::User')

        organized_resources['QA::Resource::Sandbox'] = sandboxes if sandboxes
        organized_resources['QA::Resource::Group'] = groups if groups
        # Don't try to delete projects when we're soft-deleting resources as it would result in 403 API responses
        organized_resources['QA::Resource::Project'] = projects if projects && @permanently_delete
        organized_resources.merge!(filtered_resources) unless filtered_resources.empty?
        organized_resources['QA::Resource::User'] = users if users

        organized_resources
      end

      # Returns the appropriate personal access token for API authentication
      #
      # Retrieves and memoizes a GitLab personal access token, prioritizing admin tokens
      # when available. Admin tokens (GITLAB_QA_ADMIN_ACCESS_TOKEN) are preferred for
      # environments that support admin scope operations, as they're required for
      # cleaning up User resources and other admin-level operations.
      #
      # @return [String] Personal access token for GitLab API authentication
      # @raise [SystemExit] Aborts program execution if neither token environment variable is set
      def personal_access_token
        if ENV['GITLAB_QA_ADMIN_ACCESS_TOKEN'].blank? && ENV['GITLAB_QA_ACCESS_TOKEN'].blank?
          abort("\nPlease provide either GITLAB_QA_ADMIN_ACCESS_TOKEN or GITLAB_QA_ACCESS_TOKEN")
        end

        @personal_access_token ||= ENV['GITLAB_QA_ADMIN_ACCESS_TOKEN'] || ENV['GITLAB_QA_ACCESS_TOKEN']
      end

      # Checks if a resource key is included in the PERSONAL_RESOURCES constant
      #
      # @param [String] key The resource key to check
      # @return [Boolean] true if the key is in PERSONAL_RESOURCES, false otherwise
      def personal_resource?(key)
        PERSONAL_RESOURCES.include?(key)
      end

      # Reads and parses a JSON file
      #
      # @param [String] file Path to the file to read
      # @return [Hash, Array, nil] Parsed JSON content, or nil if parsing fails
      def read_file(file)
        logger.info("Reading and processing #{file}...")
        JSON.parse(File.read(file))
      rescue JSON::ParserError
        logger.error("Failed to read #{file} - Invalid format")
        nil
      end

      # Generates a descriptive string for a resource
      #
      # @param [Hash] resource The resource hash containing resource data
      # @param [String] key The resource type key (e.g., 'QA::Resource::Project')
      # @return [String] Formatted resource description using 'info' if available, otherwise 'api_path'
      def resource_info(resource, key)
        resource['info'] ? "#{key} - #{resource['info']}" : "#{key} at #{resource['api_path']}"
      end

      # Checks if a resource exists by making a GET request to its API path
      #
      # @param [String] api_path The API path to check, may include query parameters
      # @return [Boolean] true if resource returns 404 (not found), false otherwise
      def resource_not_found?(api_path)
        # if api path contains param "?hard_delete=<boolean>", remove it
        get(Runtime::API::Request.new(api_client, api_path.split('?').first).url).code.eql? 404
      end

      # Creates a GitLab API request URL from a resource or path
      #
      # @param [Hash, String] resource_or_path Either a resource hash containing :api_path or a direct API path string
      # @param [Hash] options Additional options to pass to the API request
      # @return [String] The complete API request URL
      def resource_request(resource_or_path, **options)
        api_path = resource_or_path.is_a?(Hash) ? resource_or_path[:api_path] : resource_or_path

        Runtime::API::Request.new(api_client, api_path, **options).url
      end

      # Creates an API client using the appropriate personal access token for a given username
      #
      # @param [String] username The username to create an API client for
      # @return [Runtime::API::Client] API client configured with the user's personal access token
      def set_api_client_by_username(username)
        user_pat = if username == "gitlab-qa" && ENV['GITLAB_QA_ACCESS_TOKEN']
                     ENV['GITLAB_QA_ACCESS_TOKEN']
                   elsif username == "gitlab-qa-user1" && ENV['GITLAB_QA_USER1_ACCESS_TOKEN']
                     ENV['GITLAB_QA_USER1_ACCESS_TOKEN']
                   elsif username == "gitlab-qa-user2" && ENV['GITLAB_QA_USER2_ACCESS_TOKEN']
                     ENV['GITLAB_QA_USER2_ACCESS_TOKEN']
                   else
                     personal_access_token
                   end

        Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: user_pat)
      end

      # Temporarily switches the API client context for the duration of the block
      #
      # This method allows for temporary client switching, which is useful for operations
      # that need to be performed with different authentication credentials (e.g., personal
      # resource deletion with user-specific tokens).
      #
      # @param [Runtime::API::Client] client The API client to use temporarily
      # @yield [] The block to execute with the temporary client
      # @return [Object] The return value of the yielded block
      # @example
      #   user_client = set_api_client_by_username('gitlab-qa-user1')
      #   with_api_client(user_client) do
      #     delete_resource(personal_resource)
      #   end
      def with_api_client(client)
        original_client = @api_client
        @api_client = client
        yield
      ensure
        @api_client = original_client
      end
    end
  end
end
