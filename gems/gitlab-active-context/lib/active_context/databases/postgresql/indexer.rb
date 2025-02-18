# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class Indexer
        include ActiveContext::Databases::Concerns::Indexer

        BATCH_SIZE = 1_000

        def initialize(...)
          super
          @operations = []
        end

        def add_ref(ref)
          @refs << ref
          @operations << build_operation(ref)

          refs.size >= BATCH_SIZE
        end

        def empty?
          refs.empty?
        end

        def bulk
          client.bulk_process(@operations)
        end

        def process_bulk_errors(result)
          # we already return only failed references so nothing to do here
          result
        end

        def reset
          super
          @operations = []
        end

        private

        def build_operation(ref)
          case ref.operation.to_sym
          when :upsert
            { "#{ref.partition_name}": { upsert: build_indexed_json(ref) }, ref: ref }
          when :delete
            { "#{ref.partition_name}": { delete: ref.identifier }, ref: ref }
          else
            raise StandardError, "Operation #{ref.operation} is not supported"
          end
        end

        def build_indexed_json(ref)
          ref.as_indexed_json
            .merge(partition_id: ref.partition_number)
            .transform_values { |value| convert_pg_array(value) }
        end

        def convert_pg_array(value)
          value.is_a?(Array) ? "[#{value.join(',')}]" : value
        end
      end
    end
  end
end
