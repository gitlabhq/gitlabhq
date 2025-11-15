# frozen_string_literal: true

require 'google/cloud/storage'

module Gitlab
  module Database
    module Capture
      module StorageConnectors
        # Google Cloud Storage Connector
        # https://cloud.google.com/ruby/docs/reference/google-cloud-storage/latest
        class Gcs
          def initialize(settings)
            @settings = settings
          end

          # We have to escape "/" from the filename to avoid gcp to interpret as a subfolder. This can be a problem
          # if we use the primary write location compose the filename, which can include an address like +"1F/4BE69098"+
          def upload(filename, data)
            bucket.create_file(
              StringIO.new(data),
              CGI.escape(filename),
              metadata: {
                original_filename: filename,
                encoded: true
              }
            )
          end

          private

          attr_reader :settings

          def client
            @client ||= Google::Cloud::Storage.new(project_id: settings.project_id)
          end

          # Permission 'storage.buckets.get' must be granted to access to the Google Cloud Storage bucket
          def bucket
            @bucket ||= client.bucket(settings.bucket)
          end
        end
      end
    end
  end
end
