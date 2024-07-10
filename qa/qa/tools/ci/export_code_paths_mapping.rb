# frozen_string_literal: true

require "fog/google"

module QA
  module Tools
    module Ci
      class ExportCodePathsMapping
        include Helpers

        PROJECT = "gitlab-qa-resources"
        BUCKET = "code-path-mappings"

        def self.export(mapping_files_glob)
          new(mapping_files_glob).export
        end

        def initialize(mapping_files_glob)
          @mapping_files_glob = mapping_files_glob
        end

        # Export code path mappings to GCP
        #
        # @return [void]
        def export
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

        private

        attr_reader :mapping_files_glob

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
      end
    end
  end
end
