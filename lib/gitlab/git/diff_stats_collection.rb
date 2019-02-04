# frozen_string_literal: true

module Gitlab
  module Git
    class DiffStatsCollection
      include Gitlab::Utils::StrongMemoize
      include Enumerable

      def initialize(diff_stats)
        @collection = diff_stats
      end

      def each(&block)
        @collection.each(&block)
      end

      def find_by_path(path)
        indexed_by_path[path]
      end

      def paths
        @collection.map(&:path)
      end

      private

      def indexed_by_path
        strong_memoize(:indexed_by_path) do
          index_by { |stats| stats.path }
        end
      end
    end
  end
end
