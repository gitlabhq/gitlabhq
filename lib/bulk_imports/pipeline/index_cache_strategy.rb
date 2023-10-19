# frozen_string_literal: true

module BulkImports
  module Pipeline
    module IndexCacheStrategy
      def already_processed?(_, index)
        last_index = Gitlab::Cache::Import::Caching.read(cache_key)
        last_index && last_index.to_i >= index
      end

      def save_processed_entry(_, index)
        Gitlab::Cache::Import::Caching.write(cache_key, index)
      end
    end
  end
end
