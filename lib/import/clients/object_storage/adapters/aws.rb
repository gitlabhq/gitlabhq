# frozen_string_literal: true

module Import
  module Clients
    class ObjectStorage
      module Adapters
        # Adapter for AWS S3 and S3-compatible object storage, backed by fog-aws.
        class Aws < Base
          private

          def bucket_accessible?
            storage.head_bucket(bucket).status == 200
          end

          def fog_provider
            'AWS'
          end

          def apply_list_pagination(files)
            files.max_keys = LIST_OBJECT_KEYS_PAGE_SIZE
          end

          def provider_error_classes
            [Fog::Errors::Error, Excon::Error]
          end

          def wrapped_object_storage_errors(error_class, message, extra_log_context: {})
            super
          rescue NoMethodError => e
            # Fog currently mishandles redirects, resulting in a NoMethodError when
            # parsing the response body from AWS. If the cause here is an ExconError,
            # we treat it as a failure of the operation the caller was performing.
            raise e unless e.cause.is_a?(Excon::Error)

            Gitlab::ErrorTracking.track_exception(e, **base_log_context, **extra_log_context)
            raise error_class, message
          end
        end
      end
    end
  end
end
