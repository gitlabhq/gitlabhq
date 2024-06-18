# frozen_string_literal: true

require 'fog/google'

module QA
  module Support
    module GcsTools
      # GCS Client
      #
      # @return [Fog::Storage::Google]
      def gcs_client
        Fog::Storage::Google.new(
          google_project: ENV['QA_METRICS_GCS_PROJECT_ID'] || raise('Missing QA_METRICS_GCS_PROJECT_ID env variable'),
          **gcs_credentials)
      end

      # GCS Credentials
      #
      # @return [Hash]
      def gcs_credentials
        json_key = ENV['QA_METRICS_GCS_CREDS'] || raise(
          'QA_METRICS_GCS_CREDS env variable is required!'
        )
        return { google_json_key_location: json_key } if File.exist?(json_key)

        { google_json_key_string: json_key }
      end
    end
  end
end
