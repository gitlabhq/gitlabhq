# frozen_string_literal: true

module Gitlab
  module Cache
    class << self
      # Utility method for performing a fetch but only
      # once per request, storing the returned value in
      # the request store, if active.
      def fetch_once(key, **kwargs)
        Gitlab::SafeRequestStore.fetch(key) do
          Rails.cache.fetch(key, **kwargs) do
            yield
          end
        end
      end

      # Hook for EE
      def delete(key)
        Rails.cache.delete(key)
      end
    end
  end
end

Gitlab::Cache.prepend_mod
