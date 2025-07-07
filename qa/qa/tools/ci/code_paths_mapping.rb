# frozen_string_literal: true

require "fog/google"

module QA
  module Tools
    module Ci
      class CodePathsMapping
        include Helpers

        PROJECT = "gitlab-qa-resources"
        DEFAULT_BUCKET = "code-path-mappings"
        DEFAULT_FILE_NAME = "test-code-paths-mapping-merged-pipeline"

        def self.export(mapping_files_glob, **kwargs)
          if kwargs.key?(:bucket) || kwargs.key?(:file_name)
            new.export(mapping_files_glob, **kwargs)
          else
            new.export(mapping_files_glob)
          end
        end

        # Export code path mappings to GCP
        #
        # @param [String] mapping_files_glob - glob pattern for mapping files
        # @param [String] bucket - custom bucket name (optional)
        # @param [String] file_name - custom file name (optional)
        # @return [void]
        def export(mapping_files_glob, bucket: DEFAULT_BUCKET, file_name: DEFAULT_FILE_NAME)
          mapping_files = Dir.glob(mapping_files_glob)
          return logger.warn("No files matched pattern, skipping coverage mapping upload") if mapping_files.empty?

          unless ENV["QA_RUN_TYPE"].present?
            return logger.warn("QA_RUN_TYPE variable is not set, skipping coverage mapping upload")
          end

          logger.info("Number of mapping files found: #{mapping_files.size}")

          mapping_data = mapping_files.flat_map { |file| JSON.parse(File.read(file)) }.reduce(:merge!)
          file = "#{ENV['CI_COMMIT_REF_SLUG']}/#{ENV['QA_RUN_TYPE']}/#{file_name}-#{\
          ENV['CI_PIPELINE_ID'] || 'local'}.json"
          upload_to_gcs(file, mapping_data, bucket)
        end

        # Import code path mappings from GCP
        #
        # @param [String] branch - branch name
        # @param [String] run_type - run type
        # @param [String] bucket - custom bucket name (optional)
        # @param [String] file_name - custom file name base (optional)
        # @return [Hash]
        def import(branch, run_type, bucket: DEFAULT_BUCKET, file_name: DEFAULT_FILE_NAME)
          prefix = "#{branch}/#{run_type}/#{file_name}"

          filename = code_paths_mapping_file(prefix, bucket)

          logger.info("The mapping file fetched in import: #{filename}")
          file = client.get_object(bucket, filename)
          JSON.parse(file[:body])
        rescue StandardError => e
          logger.error("Failed to download code paths mapping from GCS. Error: #{e}")
          logger.error("Backtrace: #{e.backtrace}")
          nil # Ensure it returns nil in case of GCS errors
        end

        private

        def upload_to_gcs(file_name, mapping_data, bucket)
          client.put_object(bucket, file_name, JSON.pretty_generate(mapping_data))
          logger.info("Successfully uploaded to bucket: #{bucket}, file: #{file_name}")
        rescue StandardError => e
          logger.error("Failed to upload code paths mapping to GCS. Error: #{e}")
          logger.error("Backtrace: #{e.backtrace}")
        end

        # GCS client
        #
        # @return [Fog::Google::StorageJSON]
        def client
          @client ||= Fog::Google::Storage.new(google_project: PROJECT, **gcs_credentials)
        end

        # GCS credentials json
        #
        # @return [Hash]
        def gcs_credentials
          json_key =  ENV.fetch("QA_CODE_PATH_MAPPINGS_GCS_CREDENTIALS") do
            raise "QA_CODE_PATH_MAPPINGS_GCS_CREDENTIALS env variable is required!"
          end

          return { google_json_key_location: json_key } if File.exist?(json_key)

          { google_json_key_string: json_key }
        end

        # Code paths mapping file from GCS
        #
        # Get most up to date mapping file based on pipeline type
        # @return [String]
        def code_paths_mapping_file(prefix, bucket = DEFAULT_BUCKET)
          paginated_list(client.list_objects(bucket, prefix: prefix)).last&.name
        end

        # Paginated list of items
        #
        # @param [Google::Apis::StorageV1::Objects] list
        # @return [Array]
        def paginated_list(list)
          return [] if list.items.nil?
          return list.items if list.next_page_token.nil?

          paginated_list(
            client.list_objects(list.bucket, prefix: list.prefixes.first, page_token: list.next_page_token)
          ) + list.items
        end
      end
    end
  end
end
