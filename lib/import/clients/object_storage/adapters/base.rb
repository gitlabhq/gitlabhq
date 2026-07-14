# frozen_string_literal: true

module Import
  module Clients
    class ObjectStorage
      module Adapters
        # Base adapter holding the object storage operations that are uniform across
        # Fog providers. Provider-specific behaviour (Fog provider name, credential
        # mapping, listing pagination and the set of errors to rescue) is supplied by
        # subclasses through the hooks below.
        class Base
          include Gitlab::Utils::StrongMemoize

          def initialize(provider:, bucket:, credentials:)
            @provider = provider
            @bucket = bucket
            @credentials = credentials
          end

          def request_url(object_key)
            storage.request_url(bucket_name: bucket, object_name: object_key)
          end

          def test_connection!
            wrapped_object_storage_errors(ConnectionError,
              s_('OfflineTransfer|Unable to access object storage bucket.')) do
              bucket_accessible?
            end
          end

          # Returns all object keys in the bucket matching the given prefix.
          #
          # Uses Fog's lazy pagination to fetch keys in batches of LIST_OBJECT_KEYS_PAGE_SIZE.
          # Only object metadata is retrieved; file contents are not downloaded.
          #
          # @param object_key_prefix [String] the prefix to filter object keys by
          # @return [Array<String>] list object keys with the provided prefix
          # @raise [ConnectionError] if the object storage bucket cannot be accessed
          def object_keys_for_prefix(object_key_prefix)
            wrapped_object_storage_errors(ConnectionError, 'Unable to list objects in prefix',
              extra_log_context: { object_key_prefix: object_key_prefix }) do
              directory = storage.directories.new(key: bucket)
              directory.files.prefix = object_key_prefix
              apply_list_pagination(directory.files)

              directory.files.map(&:key)
            end
          end

          def store_file(object_key, local_path)
            check_for_path_traversal!(local_path)
            validate_file_exists!(local_path)

            wrapped_object_storage_errors(UploadError, 'Object storage upload failed',
              extra_log_context: { object_key: object_key, local_path: local_path }) do
              directory = storage.directories.new(key: bucket)
              File.open(local_path, 'rb') do |file|
                directory.files.create(
                  key: object_key,
                  body: file,
                  multipart_chunk_size: MULTIPART_THRESHOLD
                )
              end
              true
            end
          end

          def stream(object_key, &block)
            wrapped_object_storage_errors(DownloadError, 'Object storage download failed',
              extra_log_context: { object_key: object_key }) do
              directory = storage.directories.new(key: bucket)
              file = directory.files.get(object_key, &block)

              raise DownloadError, "Object not found" unless file

              true
            end
          end

          private

          attr_reader :provider, :credentials, :bucket

          # @return [Boolean] whether the bucket exists and is reachable with the
          #   given credentials. fog providers expose different calls for this
          #   (head_bucket vs get_bucket), so each adapter implements its own.
          def bucket_accessible?
            raise Gitlab::AbstractMethodError
          end

          # @return [String] the Fog provider name (e.g. 'AWS', 'Google')
          def fog_provider
            raise Gitlab::AbstractMethodError
          end

          # @return [Hash] credentials passed as keyword arguments to Fog::Storage.new
          def fog_credentials
            credentials
          end

          # Applies the provider-specific page size to a Fog files collection.
          # @return [void]
          def apply_list_pagination(_files)
            raise Gitlab::AbstractMethodError
          end

          # @return [Array<Class>] the exception classes treated as recoverable
          #   object storage errors for this provider
          def provider_error_classes
            raise Gitlab::AbstractMethodError
          end

          def storage
            ::Fog::Storage.new(provider: fog_provider, **fog_credentials)
          end
          strong_memoize_attr :storage

          def validate_file_exists!(local_path)
            return if File.exist?(local_path)

            raise UploadError, "File not found: #{local_path}"
          end

          def check_for_path_traversal!(local_path)
            Gitlab::PathTraversal.check_path_traversal!(local_path)
          end

          def base_log_context
            { provider: provider, bucket: bucket }
          end

          # Executes the given block, rescuing provider-specific errors and re-raising
          # them as a uniform +error_class+.
          #
          # **Important contract:** the block MUST return a truthy value on success.
          # A falsy return value (+false+ or +nil+) is treated as a failure and will
          # raise +error_class+ with +message+, exactly as if a provider error had
          # been rescued. Do NOT use this wrapper for operations whose legitimate
          # return value may be +false+ or +nil+; have those callers raise explicitly
          # instead.
          #
          # @param error_class [Class] the error class to raise on failure
          # @param message [String] the human-readable failure message
          # @param extra_log_context [Hash] additional key/value pairs merged into the
          #   error-tracking context
          # @yieldreturn [truthy] a truthy value indicating success
          # @raise [error_class] if the block returns falsy or a provider error is raised
          def wrapped_object_storage_errors(error_class, message, extra_log_context: {})
            result = yield
            raise error_class, message unless result

            result
          rescue *provider_error_classes => e
            Gitlab::ErrorTracking.track_exception(e, **base_log_context, **extra_log_context)
            raise error_class, message
          end
        end
      end
    end
  end
end
