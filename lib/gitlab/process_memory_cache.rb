# frozen_string_literal: true

module Gitlab
  class ProcessMemoryCache
    # ActiveSupport::Cache::MemoryStore is thread-safe:
    # https://github.com/rails/rails/blob/2f1fefe456932a6d7d2b155d27b5315c33f3daa1/activesupport/lib/active_support/cache/memory_store.rb#L19
    @cache = ActiveSupport::Cache::MemoryStore.new

    def self.cache_backend
      @cache
    end
  end
end
