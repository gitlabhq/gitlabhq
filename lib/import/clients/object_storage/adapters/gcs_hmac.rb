# frozen_string_literal: true

module Import
  module Clients
    class ObjectStorage
      module Adapters
        # Adapter for Google Cloud Storage accessed through its S3-compatible XML
        # API using HMAC interoperability keys.
        #
        # GCS's S3 interoperability endpoint speaks the same protocol as AWS S3, so
        # we reuse the fog-aws backend (via the Aws adapter) with the GCS endpoint
        # preset, rather than fog-google's separate XML backend. The user supplies
        # only the HMAC key pair (and region); they do not need to know the endpoint.
        class GcsHmac < Aws
          GCS_S3_ENDPOINT = 'https://storage.googleapis.com'

          private

          def fog_credentials
            creds = credentials.with_indifferent_access

            {
              aws_access_key_id: creds[:google_storage_access_key_id],
              aws_secret_access_key: creds[:google_storage_secret_access_key],
              region: creds[:region],
              path_style: creds.fetch(:path_style, true),
              endpoint: GCS_S3_ENDPOINT
            }
          end
        end
      end
    end
  end
end
