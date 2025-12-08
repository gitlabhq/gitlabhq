# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class DefinitionsCollector
        def initialize(mapping)
          @collection = []
          @mapping = mapping
        end

        def collect(&definitions_block)
          instance_exec(&definitions_block)

          @collection
        end

        private

        def method_missing(method_name, ...)
          return super unless @mapping[method_name]

          @collection << @mapping[method_name].new(...)
        end

        def respond_to_missing?(method_name, ...)
          @mapping.key?(method_name) || super
        end
      end
    end
  end
end
