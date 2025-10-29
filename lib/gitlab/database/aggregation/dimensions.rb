# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class Dimensions
        include Enumerable

        def initialize(mapping)
          @dimensions = []
          @mapping = mapping
        end

        def column(...)
          @dimensions << @mapping[:column].new(...)
        end

        def timestamp_column(...)
          @dimensions << @mapping[:timestamp_column].new(...)
        end

        def each(&block)
          @dimensions.each(&block)
        end
      end
    end
  end
end
