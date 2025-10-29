# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class Metrics
        include Enumerable

        def initialize(mapping)
          @metrics = []
          @mapping = mapping
        end

        def mean(...)
          @metrics << @mapping[:mean].new(...)
        end

        def count(...)
          @metrics << @mapping[:count].new(...)
        end

        def each(&block)
          @metrics.each(&block)
        end
      end
    end
  end
end
