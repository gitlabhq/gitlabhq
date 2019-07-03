# frozen_string_literal: true

module Gitlab
  class ThreadMemoryCache
    THREAD_KEY = :thread_memory_cache

    def self.cache_backend
      # Note ActiveSupport::Cache::MemoryStore is thread-safe.  Since
      # each backend is local per thread we probably don't need to worry
      # about synchronizing access, but this is a drop-in replacement
      # for ActiveSupport::Cache::RedisStore.
      Thread.current[THREAD_KEY] ||= ActiveSupport::Cache::MemoryStore.new
    end
  end
end
