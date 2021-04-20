# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchLfsOidLoader
        def initialize(repository, blob_id)
          @repository = repository
          @blob_id = blob_id
        end

        def find
          BatchLoader::GraphQL.for(blob_id).batch(key: repository) do |blob_ids, loader, batch_args|
            Gitlab::Git::Blob.batch_lfs_pointers(batch_args[:key], blob_ids).each do |loaded_blob|
              loader.call(loaded_blob.id, loaded_blob.lfs_oid)
            end
          end
        end

        private

        attr_reader :repository, :blob_id
      end
    end
  end
end
