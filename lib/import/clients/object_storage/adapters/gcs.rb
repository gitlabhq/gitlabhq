# frozen_string_literal: true

module Import
  module Clients
    class ObjectStorage
      module Adapters
        # Adapter for Google Cloud Storage, backed by fog-google.
        #
        # Authenticates with a service account key (provider :gcs).
        class Gcs < Base
          # fog-google resolves the storage API host from this bare domain (falling
          # back to the GOOGLE_CLOUD_UNIVERSE_DOMAIN env var if unset); pinning it
          # here makes that explicit in code, rather than relying on us never
          # passing a :universe_domain option.
          GOOGLE_DEFAULT_UNIVERSE_DOMAIN = 'googleapis.com'

          # Base#request_url delegates to fog's own storage.request_url, but
          # fog-google does not implement that method, so we build the object's
          # canonical GCS URL ourselves instead, from the host the connection
          # resolved to storage.googleapis.com
          #
          # Callers only pass this URL to Gitlab::HTTP_V2::UrlBlocker, to check
          # that the object storage host isn't an SSRF target; they never use it
          # to actually fetch the object (that goes through #stream/#store_file
          # via this same connection). So it only needs to resolve to the
          # correct host, not be a fully valid, fetchable request URL.
          def request_url(object_key)
            "#{storage.bucket_base_url}#{bucket}/#{object_key}"
          end

          private

          # The configuration flattens the uploaded service account key into
          # individual fields (see Import::Offline::Configuration#flatten_gcs_json_key),
          # but fog-google wants the key back as a JSON string, so we rebuild it
          # from those fields.
          def fog_credentials
            creds = credentials.with_indifferent_access
            {
              google_project: creds[:google_project],
              google_json_key_string: Gitlab::Json.dump(creds.except(:google_project)),
              universe_domain: GOOGLE_DEFAULT_UNIVERSE_DOMAIN
            }
          end

          # fog-google's JSON backend has no head_bucket; get_bucket returns the
          # bucket metadata and raises Google::Apis::Error when it is missing or
          # inaccessible.
          def bucket_accessible?
            storage.get_bucket(bucket).present?
          end

          def fog_provider
            'Google'
          end

          def apply_list_pagination(files)
            files.max_results = LIST_OBJECT_KEYS_PAGE_SIZE
          end

          def provider_error_classes
            [Google::Apis::Error, Fog::Errors::Error, Excon::Error]
          end
        end
      end
    end
  end
end
