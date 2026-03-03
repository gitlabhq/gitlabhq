# frozen_string_literal: true

module Import
  module Clients
    class ObjectStorage
      include Gitlab::Utils::StrongMemoize

      Error = Class.new(StandardError)
      UploadError = Class.new(StandardError)
      ConnectionError = Class.new(StandardError)

      MULTIPART_THRESHOLD = 100.megabytes

      FOG_PROVIDER_MAP = {
        aws: 'AWS',
        s3_compatible: 'AWS'
      }.with_indifferent_access.freeze

      def initialize(provider:, bucket:, credentials:)
        @provider = provider
        @bucket = bucket
        @credentials = credentials
      end

      def test_connection!
        status = storage.head_bucket(bucket).status

        return if status == 200

        raise ConnectionError, format(
          s_('OfflineTransfer|Object storage request responded with status %{status}'), status: status
        )
      end

      def store_file(upload_key, local_path)
        check_for_path_traversal!(local_path)
        validate_file_exists!(local_path)

        directory = storage.directories.new(key: bucket)

        File.open(local_path, 'rb') do |file|
          directory.files.create(
            key: upload_key,
            body: file,
            multipart_chunk_size: MULTIPART_THRESHOLD
          )
        end

        true
      rescue Fog::Errors::Error, Excon::Error => e
        Gitlab::ErrorTracking.track_exception(
          e,
          provider: provider,
          bucket: bucket,
          upload_key: upload_key,
          local_path: local_path
        )
        raise UploadError, "Object storage upload failed: #{e.message}"
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
    end
  end
end
