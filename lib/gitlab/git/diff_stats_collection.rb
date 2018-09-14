# frozen_string_literal: true

module Gitlab
  module Git
    class DiffStatsCollection
      include Enumerable

      def initialize(diff_stats)
        @collection = diff_stats
      end

      def each(&block)
        @collection.each(&block)
      end
    end
  end
end
