# frozen_string_literal: true

module BulkImports
  module Pipeline
    module HexdigestCacheStrategy
      def already_processed?(data, _)
        values = Gitlab::Cache::Import::Caching.values_from_set(cache_key)
        values.include?(OpenSSL::Digest::SHA256.hexdigest(data.to_s))
      end

      def save_processed_entry(data, _)
        Gitlab::Cache::Import::Caching.set_add(cache_key, OpenSSL::Digest::SHA256.hexdigest(data.to_s))
      end
    end
  end
end
