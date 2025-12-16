# frozen_string_literal: true

module Import
  module Clients
    class ObjectStorage
      include Gitlab::Utils::StrongMemoize

      ConnectionError = Class.new(StandardError)

      FOG_PROVIDER_MAP = {
        aws: 'AWS',
        minio: 'AWS'
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

      private

      attr_reader :provider, :credentials, :bucket

      def storage
        ::Fog::Storage.new(
          provider: FOG_PROVIDER_MAP[provider],
          **credentials
        )
      end
      strong_memoize_attr :storage
    end
  end
end
