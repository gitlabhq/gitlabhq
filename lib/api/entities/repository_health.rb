# frozen_string_literal: true

module API
  module Entities
    class RepositoryHealth < Grape::Entity
      class References < Grape::Entity
        expose :loose_count,
          documentation: { type: 'Integer' }
        expose :packed_size,
          documentation: { type: 'Integer' }
        expose :reference_backend,
          documentation: { type: 'String' }
      end

      class Objects < Grape::Entity
        expose :size,
          documentation: { type: 'Integer' }
        expose :recent_size,
          documentation: { type: 'Integer' }
        expose :stale_size,
          documentation: { type: 'Integer' }
        expose :keep_size,
          documentation: { type: 'Integer' }
        expose :packfile_count,
          documentation: { type: 'Integer' }
        expose :reverse_index_count,
          documentation: { type: 'Integer' }
        expose :cruft_count,
          documentation: { type: 'Integer' }
        expose :keep_count,
          documentation: { type: 'Integer' }
        expose :loose_objects_count,
          documentation: { type: 'Integer' }
        expose :stale_loose_objects_count,
          documentation: { type: 'Integer' }
        expose :loose_objects_garbage_count,
          documentation: { type: 'Integer' }
      end

      class CommitGraph < Grape::Entity
        expose :commit_graph_chain_length,
          documentation: { type: 'Integer' }
        expose :has_bloom_filters,
          documentation: { type: 'Boolean' }
        expose :has_generation_data,
          documentation: { type: 'Boolean' }
        expose :has_generation_data_overflow,
          documentation: { type: 'Boolean' }
      end

      class MultiPackIndex < Grape::Entity
        expose :packfile_count,
          documentation: { type: 'Integer' }
        expose :version,
          documentation: { type: 'Integer' }
      end

      class Bitmap < Grape::Entity
        expose :has_hash_cache,
          documentation: { type: 'Boolean' }
        expose :has_lookup_table,
          documentation: { type: 'Boolean' }
        expose :version,
          documentation: { type: 'Integer' }
      end

      class AlternatesInfo < Grape::Entity
        expose :object_directories,
          documentation: { type: 'Array', items: { type: 'string' } }
        expose :last_modified,
          documentation: { type: 'DateTime', example: '2025-02-24T09:05:50.355Z' }
      end

      class LastFullRepack < Grape::Entity
        expose :seconds,
          documentation: { type: 'Integer' }
        expose :nanos,
          documentation: { type: 'Integer' }
      end

      expose :size, documentation: { type: 'Integer' }
      expose :references, using: References
      expose :objects, using: Objects
      expose :commit_graph, using: CommitGraph
      expose :bitmap, using: Bitmap
      expose :multi_pack_index, using: MultiPackIndex
      expose :multi_pack_index_bitmap, using: Bitmap
      expose :alternates, documentation: { type: 'object', example: nil }
      expose :is_object_pool, documentation: { type: 'Boolean' }
      expose :last_full_repack, using: LastFullRepack
      expose :updated_at, documentation: { type: 'DateTime', example: '2025-02-24T09:05:50.355Z' }
    end
  end
end
