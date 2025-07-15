# frozen_string_literal: true

module Import
  module Framework
    module ProgressTracking
      CACHE_EXPIRATION = 3.days.to_i

      def with_progress_tracking(scope:, data:)
        return true if processed_entry?(scope: scope, data: data)

        result = yield

        save_processed_entry(scope: scope, data: data)

        result
      end

      def save_processed_entry(scope:, data:)
        Gitlab::Cache::Import::Caching.set_add(cache_key(scope), data, timeout: CACHE_EXPIRATION)
      end

      def processed_entry?(scope:, data:)
        Gitlab::Cache::Import::Caching.set_includes?(cache_key(scope), data)
      end

      private

      def cache_key(scope)
        "progress-tracking:#{self.class.name.demodulize.underscore}:#{scope_string(scope)}"
      end

      def scope_string(scope)
        scope.flat_map { |key, value| [key, value] }.join(':')
      end
    end
  end
end
