# frozen_string_literal: true

require "fog/google"

module QA
  module Tools
    module Ci
      class CodePathsMapping
        include Helpers

        PROJECT = "gitlab-qa-resources"
        BUCKET = "code-path-mappings"

        def self.export(mapping_files_glob)
          new.export(mapping_files_glob)
        end

        # Export code path mappings to GCP
        #
        # @param [String] mapping_files_glob - glob pattern for mapping files
        # @return [void]
        def export(mapping_files_glob)
          mapping_files = Dir.glob(mapping_files_glob)
          return logger.warn("No files matched pattern, skipping coverage mapping upload") if mapping_files.empty?

          unless ENV["QA_RUN_TYPE"].present?
            return logger.warn("QA_RUN_TYPE variable is not set, skipping coverage mapping upload")
          end

          logger.info("Number of mapping files found: #{mapping_files.size}")

          mapping_data = mapping_files.flat_map { |file| JSON.parse(File.read(file)) }.reduce(:merge!)
          file = "#{ENV['CI_COMMIT_REF_SLUG']}/#{ENV['QA_RUN_TYPE']}/test-code-paths-mapping-merged-pipeline-#{\
          ENV['CI_PIPELINE_ID'] || 'local'}.json"
          upload_to_gcs(file, mapping_data)
        end

        # Import code path mappings from GCP
        #
        # @param [String] branch - branch name
        # @param [String] run_type - run type
        # @return [Hash]
        def import(branch, run_type)
          filename = code_paths_mapping_file("#{branch}/#{run_type}")

          logger.info("The mapping file fetched in import: #{filename}")
          file = client.get_object(BUCKET, filename)
          JSON.parse(file[:body])
        rescue StandardError => e
          logger.error("Failed to download code paths mapping from GCS. Error: #{e}")
          logger.error("Backtrace: #{e.backtrace}")
          nil # Ensure it returns nil in case of GCS errors
        end

        private

        def upload_to_gcs(file_name, mapping_data)
          client.put_object(BUCKET, file_name, JSON.pretty_generate(mapping_data))
        rescue StandardError => e
          logger.error("Failed to upload code paths mapping to GCS. Error: #{e}")
          logger.error("Backtrace: #{e.backtrace}")
        end

        # GCS client
        #
        # @return [Fog::Storage::GoogleJSON]
        def client
          @client ||= Fog::Storage::Google.new(google_project: PROJECT, **gcs_credentials)
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
        def code_paths_mapping_file(prefix)
          paginated_list(client.list_objects(BUCKET, prefix: prefix)).last&.name
        end

        # Paginated list of items
        #
        # @param [Google::Apis::StorageV1::Objects] list
        # @return [Array]
        def paginated_list(list)
          return [] if list.items.nil?
          return list.items if list.next_page_token.nil?

          paginated_list(
            client.list_objects(BUCKET, prefix: list.prefixes.first, page_token: list.next_page_token)
          ) + list.items
        end
      end
    end
  end
end
