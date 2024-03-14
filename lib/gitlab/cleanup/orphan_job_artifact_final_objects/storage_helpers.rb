# frozen_string_literal: true

module Gitlab
  module Cleanup
    module OrphanJobArtifactFinalObjects
      module StorageHelpers
        include Gitlab::Utils::StrongMemoize

        def connection
          ::Fog::Storage.new(configuration['connection'].symbolize_keys)
        end

        def configuration
          Gitlab.config.artifacts.object_store
        end

        def bucket
          configuration.remote_directory
        end

        def bucket_prefix
          configuration.bucket_prefix
        end

        def artifacts_directory
          connection.directories.new(key: bucket)
        end
        strong_memoize_attr :artifacts_directory
      end
    end
  end
end
