# frozen_string_literal: true

# This concern contains shared functionality for bulk indexing documents in Elasticsearch and OpenSearch databases.

module ActiveContext
  module Databases
    module Concerns
      module ElasticIndexer
        include ActiveContext::Databases::Concerns::Indexer

        DEFAULT_MAX_BULK_SIZE = 10.megabytes

        attr_reader :operations, :bulk_size

        def initialize(...)
          super
          @operations = []
          @bulk_size = 0
        end

        def add_ref(ref)
          operation = build_operation(ref)
          @refs << ref
          @operations << operation
          @bulk_size += calculate_operation_size(operation)

          bulk_size >= bulk_threshold
        end

        def empty?
          operations.empty?
        end

        def bulk
          client.bulk(body: operations.flatten)
        end

        def process_bulk_errors(result)
          return [] unless result['errors']

          failed_refs = []

          result['items'].each_with_index do |item, index|
            op = item['index'] || item['update'] || item['delete']

            next unless op.nil? || op['error']

            ref = refs[index]

            logger.warn(
              'message' => 'indexing_failed',
              'meta.indexing.error' => op&.dig('error') || 'Operation was nil',
              'meta.indexing.status' => op&.dig('status'),
              'meta.indexing.operation_type' => item.each_key.first,
              'meta.indexing.ref' => ref.serialize,
              'meta.indexing.identifier' => ref.identifier
            )

            failed_refs << ref
          end

          failed_refs
        end

        def reset
          super
          @operations = []
          @bulk_size = 0
        end

        private

        def build_operation(ref)
          case ref.operation.to_sym
          when :index, :upsert
            [
              { update: { _index: ref.partition_name, _id: ref.identifier, routing: ref.routing }.compact },
              { doc: ref.as_indexed_json, doc_as_upsert: true }
            ]
          when :delete
            [{ delete: { _index: ref.partition_name, _id: ref.identifier, routing: ref.routing }.compact }]
          else
            raise StandardError, "Operation #{ref.operation} is not supported"
          end
        end

        def calculate_operation_size(operation)
          operation.to_json.bytesize + 2 # Account for newlines
        end

        def bulk_threshold
          @bulk_threshold ||= options[:max_bulk_size_bytes] || DEFAULT_MAX_BULK_SIZE
        end

        def logger
          @logger ||= ActiveContext::Config.logger
        end
      end
    end
  end
end
