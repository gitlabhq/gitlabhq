# frozen_string_literal: true

module BulkImports
  class UsersMapper
    include Gitlab::Utils::StrongMemoize

    SOURCE_USER_IDS_CACHE_KEY = 'bulk_imports/%{bulk_import}/%{entity}/source_user_ids'

    def initialize(context:)
      @context = context
      @cache_key = SOURCE_USER_IDS_CACHE_KEY % {
        bulk_import: @context.bulk_import.id,
        entity: @context.entity.id
      }
    end

    def map
      strong_memoize(:map) do
        map = hash_with_default

        cached_source_user_ids.each_pair do |source_id, destination_id|
          map[source_id.to_i] = destination_id.to_i
        end

        map
      end
    end

    def include?(source_user_id)
      map.has_key?(source_user_id)
    end

    def default_user_id
      @context.current_user.id
    end

    def cache_source_user_id(source_id, destination_id)
      ::Gitlab::Cache::Import::Caching.hash_add(@cache_key, source_id, destination_id)
    end

    private

    def hash_with_default
      Hash.new { default_user_id }
    end

    def cached_source_user_ids
      ::Gitlab::Cache::Import::Caching.values_from_hash(@cache_key)
    end
  end
end
