# frozen_string_literal: true
#
module Gitlab
  module Diff
    class StatsCache
      include Gitlab::Metrics::Methods
      include Gitlab::Utils::StrongMemoize

      EXPIRATION = 1.week
      VERSION = 1

      def initialize(cachable_key:)
        @cachable_key = cachable_key
      end

      def read
        strong_memoize(:cached_values) do
          content = cache.fetch(key)

          next unless content

          stats = content.map { |stat| Gitaly::DiffStats.new(stat) }

          Gitlab::Git::DiffStatsCollection.new(stats)
        end
      end

      def write_if_empty(stats)
        return if cache.exist?(key)
        return unless stats

        cache.write(key, stats.as_json, expires_in: EXPIRATION)
      end

      def clear
        cache.delete(key)
      end

      private

      attr_reader :cachable_key

      def cache
        Rails.cache
      end

      def key
        strong_memoize(:redis_key) do
          ['diff_stats', cachable_key, VERSION].join(":")
        end
      end
    end
  end
end
