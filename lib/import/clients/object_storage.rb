# frozen_string_literal: true

module Import
  module Clients
    class ObjectStorage
      include Gitlab::Utils::StrongMemoize

      DownloadError = Class.new(StandardError)
      UploadError = Class.new(StandardError)
      ConnectionError = Class.new(StandardError)

      LIST_OBJECT_KEYS_PAGE_SIZE = 1000
      MULTIPART_THRESHOLD = 100.megabytes
      PREFIX_SEPARATOR = '/'

      FOG_PROVIDER_MAP = {
        aws: 'AWS',
        s3_compatible: 'AWS'
      }.with_indifferent_access.freeze

      FOG_ERRORS = [Fog::Errors::Error, Excon::Error].freeze

      def initialize(provider:, bucket:, credentials:)
        @provider = provider
        @bucket = bucket
        @credentials = credentials
      end

      def request_url(object_key)
        storage.request_url(bucket_name: bucket, object_name: object_key)
      end

      def test_connection!
        wrapped_object_storage_errors(ConnectionError, s_('OfflineTransfer|Unable to access object storage bucket.')) do
          storage.head_bucket(bucket).status == 200
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
          directory.files.max_keys = LIST_OBJECT_KEYS_PAGE_SIZE

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

      def validate_file_exists!(local_path)
        return if File.exist?(local_path)

        raise UploadError, "File not found: #{local_path}"
      end

      def storage
        ::Fog::Storage.new(
          provider: FOG_PROVIDER_MAP[provider],
          **credentials
        )
      end
      strong_memoize_attr :storage

      def check_for_path_traversal!(local_path)
        Gitlab::PathTraversal.check_path_traversal!(local_path)
      end

      def base_log_context
        { provider: provider, bucket: bucket }
      end

      def wrapped_object_storage_errors(error_class, message, extra_log_context: {})
        result = yield
        raise error_class, message unless result

        result
      rescue *FOG_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e, **base_log_context, **extra_log_context)
        raise error_class, message
      rescue NoMethodError => e
        # Fog currently mishandles redirects, resulting in a NoMethodError when
        # parsing the response body from AWS. If the cause here is an ExconError,
        # we treat it as a failed connection.
        if e.cause.is_a?(Excon::Error)
          Gitlab::ErrorTracking.track_exception(e, **base_log_context, **extra_log_context)
          raise error_class, s_('OfflineTransfer|Unable to access object storage bucket.')
        end

        raise e
      end
    end
  end
end
