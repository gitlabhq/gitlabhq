# frozen_string_literal: true

module BulkImports
  class UsersMapper
    include Gitlab::Utils::StrongMemoize

    SOURCE_USER_IDS_CACHE_KEY = 'bulk_imports/%{bulk_import}/%{entity}/source_user_ids'

    SOURCE_USERNAMES_CACHE_KEY = 'bulk_imports/%{bulk_import}/%{entity}/source_usernames'

    def initialize(context:)
      @context = context
      @user_ids_cache_key = generate_cache_key(SOURCE_USER_IDS_CACHE_KEY)
      @usernames_cache_key = generate_cache_key(SOURCE_USERNAMES_CACHE_KEY)
    end

    def map
      strong_memoize(:map) do
        map = Hash.new { default_user_id }

        cached_source_user_ids.each_pair do |source_id, destination_id|
          map[source_id.to_i] = destination_id.to_i
        end

        map
      end
    end

    def map_usernames
      strong_memoize(:map_usernames) do
        map = {}

        cached_source_usernames.each_pair do |source_username, destination_username|
          map[source_username] = destination_username
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
      ::Gitlab::Cache::Import::Caching.hash_add(@user_ids_cache_key, source_id, destination_id)
    end

    def cache_source_username(source_username, destination_username)
      ::Gitlab::Cache::Import::Caching.hash_add(@usernames_cache_key, source_username, destination_username)
    end

    private

    def generate_cache_key(pattern)
      pattern % {
        bulk_import: @context.bulk_import.id,
        entity: @context.entity.id
      }
    end

    def cached_source_user_ids
      ::Gitlab::Cache::Import::Caching.values_from_hash(@user_ids_cache_key)
    end

    def cached_source_usernames
      ::Gitlab::Cache::Import::Caching.values_from_hash(@usernames_cache_key)
    end
  end
end
