# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class DefinitionsCollector
        def initialize(mapping, transients: {})
          @collection = []
          @mapping = mapping
          @transients = transients
        end

        def collect(&definitions_block)
          instance_exec(&definitions_block)

          @collection
        end

        private

        def sql(...)
          Arel.sql(...)
        end

        def transient(name)
          @transients.fetch(name)
        end

        def gid_formatter
          ->(values) { Array.wrap(values).map { |v| GlobalID.parse(v)&.model_id&.to_i || v } }
        end

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
