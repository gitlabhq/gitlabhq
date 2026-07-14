# frozen_string_literal: true

module Import
  module Clients
    # Object storage client for offline transfer. Exposes a provider-agnostic
    # interface and delegates the actual work to a provider-specific adapter
    # (see Import::Clients::ObjectStorage::Adapters).
    class ObjectStorage
      DownloadError = Class.new(StandardError)
      UploadError = Class.new(StandardError)
      ConnectionError = Class.new(StandardError)

      LIST_OBJECT_KEYS_PAGE_SIZE = 1000
      MULTIPART_THRESHOLD = 100.megabytes
      PREFIX_SEPARATOR = '/'

      delegate :request_url, :test_connection!, :object_keys_for_prefix, :store_file, :stream, to: :adapter

      def initialize(provider:, bucket:, credentials:)
        @adapter = adapter_for(provider).new(provider: provider, bucket: bucket, credentials: credentials)
      end

      private

      attr_reader :adapter

      def adapter_for(provider)
        case provider.to_s
        when 'aws', 's3_compatible'
          Adapters::Aws
        when 'gcs'
          Adapters::Gcs
        when 'gcs_hmac'
          Adapters::GcsHmac
        else
          raise ArgumentError, "Unsupported object storage provider: #{provider}"
        end
      end
    end
  end
end
