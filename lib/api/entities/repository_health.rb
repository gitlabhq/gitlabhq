# frozen_string_literal: true

module API
  module Entities
    class RepositoryHealth < Grape::Entity
      class References < Grape::Entity
        expose :loose_count,
          documentation: { type: 'integer' }
        expose :packed_size,
          documentation: { type: 'integer' }
        expose :reference_backend,
          documentation: { type: 'string' }
      end

      class Objects < Grape::Entity
        expose :size,
          documentation: { type: 'integer' }
        expose :recent_size,
          documentation: { type: 'integer' }
        expose :stale_size,
          documentation: { type: 'integer' }
        expose :keep_size,
          documentation: { type: 'integer' }
        expose :packfile_count,
          documentation: { type: 'integer' }
        expose :reverse_index_count,
          documentation: { type: 'integer' }
        expose :cruft_count,
          documentation: { type: 'integer' }
        expose :keep_count,
          documentation: { type: 'integer' }
        expose :loose_objects_count,
          documentation: { type: 'integer' }
        expose :stale_loose_objects_count,
          documentation: { type: 'integer' }
        expose :loose_objects_garbage_count,
          documentation: { type: 'integer' }
      end

      class CommitGraph < Grape::Entity
        expose :commit_graph_chain_length,
          documentation: { type: 'integer' }
        expose :has_bloom_filters,
          documentation: { type: 'boolean' }
        expose :has_generation_data,
          documentation: { type: 'boolean' }
        expose :has_generation_data_overflow,
          documentation: { type: 'boolean' }
      end

      class MultiPackIndex < Grape::Entity
        expose :packfile_count,
          documentation: { type: 'integer' }
        expose :version,
          documentation: { type: 'integer' }
      end

      class Bitmap < Grape::Entity
        expose :has_hash_cache,
          documentation: { type: 'boolean' }
        expose :has_lookup_table,
          documentation: { type: 'boolean' }
        expose :version,
          documentation: { type: 'integer' }
      end

      class AlternatesInfo < Grape::Entity
        expose :object_directories,
          documentation: { type: 'array', items: { type: 'string' } }
        expose :last_modified,
          documentation: { type: 'dateTime', example: '2025-02-24T09:05:50.355Z' }
      end

      class LastFullRepack < Grape::Entity
        expose :seconds,
          documentation: { type: 'integer' }
        expose :nanos,
          documentation: { type: 'integer' }
      end

      expose :size, documentation: { type: 'integer' }
      expose :references, using: References
      expose :objects, using: Objects
      expose :commit_graph, using: CommitGraph
      expose :bitmap, using: Bitmap
      expose :multi_pack_index, using: MultiPackIndex
      expose :multi_pack_index_bitmap, using: Bitmap
      expose :alternates, documentation: { type: 'object', example: nil }
      expose :is_object_pool, documentation: { type: 'boolean' }
      expose :last_full_repack, using: LastFullRepack
      expose :updated_at, documentation: { type: 'dateTime', example: '2025-02-24T09:05:50.355Z' }
    end
  end
end
