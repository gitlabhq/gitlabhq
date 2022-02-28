# frozen_string_literal: true

module Gitlab
  module Ci
    class Trace
      ##
      # RemoteChecksum class is responsible for fetching the MD5 checksum of
      # an uploaded build trace.
      #
      class RemoteChecksum
        include Gitlab::Utils::StrongMemoize

        def initialize(trace_artifact)
          @trace_artifact = trace_artifact
        end

        def md5_checksum
          strong_memoize(:md5_checksum) do
            fetch_md5_checksum
          end
        end

        private

        attr_reader :trace_artifact

        delegate :aws?, :google?, to: :object_store_config, prefix: :provider

        def fetch_md5_checksum
          return unless object_store_config.enabled?
          return if trace_artifact.local_store?

          remote_checksum_value
        end

        def remote_checksum_value
          strong_memoize(:remote_checksum_value) do
            if provider_google?
              checksum_from_google
            elsif provider_aws?
              checksum_from_aws
            end
          end
        end

        def object_store_config
          strong_memoize(:object_store_config) do
            trace_artifact.file.class.object_store_config
          end
        end

        def checksum_from_google
          content_md5 = upload_attributes.fetch(:content_md5)

          Base64
            .decode64(content_md5)
            .unpack1('H*')
        end

        def checksum_from_aws
          upload_attributes.fetch(:etag)
        end

        # Carrierwave caches attributes for the local file and does not replace
        # them with the ones from object store after the upload completes.
        # We need to force it to fetch them directly from the object store.
        def upload_attributes
          strong_memoize(:upload_attributes) do
            ::Ci::JobArtifact.find(trace_artifact.id).file.file.attributes
          end
        end
      end
    end
  end
end
