# frozen_string_literal: true

# This concern contains shared functionality for bulk indexing documents in Elasticsearch and OpenSearch databases.

module ActiveContext
  module Databases
    module Concerns
      module ElasticIndexer
        include ActiveContext::Databases::Concerns::Indexer

        DEFAULT_MAX_BULK_SIZE = 10.megabytes

        attr_reader :index_operations, :bulk_size

        def initialize(...)
          super
          @index_operations = []
          @bulk_size = 0
        end

        def add_ref(ref)
          @refs << ref
          build_index_operations(ref)

          bulk_size >= bulk_threshold
        end

        def empty?
          refs.empty?
        end

        # Executes upsert operations in one bulk request
        # Create a single delete_by_query request for processing deletes
        def bulk
          results = []

          results << client.bulk(body: index_operations.flatten, refresh: true) unless index_operations.empty?

          build_delete_operations.each do |op|
            results << client.delete_by_query(
              index: op[:index],
              body: op[:body]
            )
          end

          results
        end

        def process_bulk_errors(results)
          failed_refs_set = Set.new

          results.each do |result|
            next unless result['errors']

            result['items'].each do |item|
              op = item['index'] || item['update'] || item['delete']

              next unless op.nil? || op['error']

              ref = refs.find { |ref| ref.identifier == extract_identifier(op['_id']) }

              logger.warn(
                'message' => 'indexing_failed',
                'meta.indexing.error' => op&.dig('error') || 'Operation was nil',
                'meta.indexing.status' => op&.dig('status'),
                'meta.indexing.operation_type' => item.each_key.first,
                'meta.indexing.ref' => ref&.serialize,
                'meta.indexing.identifier' => ref&.identifier
              )

              failed_refs_set.add(ref) if ref
            end
          end

          failed_refs_set.to_a
        end

        def reset
          super
          @index_operations = []
          @bulk_size = 0
        end

        private

        # Builds an upsert operation for every ref where operation is :upsert
        # These operations will be processed in bulk
        def build_index_operations(ref)
          return unless ref.operation.to_sym == :upsert

          ref.jsons.map.with_index do |hash, index|
            add_index_operation([
              { update: { _index: ref.partition, _id: unique_identifier(ref, index), routing: ref.routing }.compact },
              { doc: hash, doc_as_upsert: true }
            ])
          end
        end

        # Builds up a bool query containing multiple shoulds:
        #   A single terms query containing ids of refs where operation is :delete
        #   A bool query with a `filter` for the `ref_id` and `must_not` for the `ref_version` for :upsert refs
        #     This ensures we only delete old versions of the document
        def build_delete_operations
          delete_operations = []

          refs.group_by(&:partition).each do |partition, partition_refs|
            shoulds = []
            ref_ids_to_delete = []

            partition_refs.each do |ref|
              case ref.operation.to_sym
              when :upsert
                shoulds << delete_with_version_query(ref)
              when :delete
                ref_ids_to_delete << ref.identifier
              else
                raise StandardError, "Operation #{ref.operation} is not supported"
              end
            end

            delete_operations << { index: partition, body: build_delete_query(shoulds, ref_ids_to_delete) }
          end

          delete_operations
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

        def add_index_operation(op)
          @index_operations << op
          @bulk_size += calculate_operation_size(op)
        end

        def delete_without_version_query(ref_ids)
          { terms: { ref_id: ref_ids } }
        end

        def delete_with_version_query(ref)
          {
            bool: {
              filter: { term: { ref_id: ref.identifier } },
              must_not: { term: { ref_version: ref.ref_version } }
            }
          }
        end

        def build_delete_query(shoulds, ref_ids_to_delete)
          shoulds << delete_without_version_query(ref_ids_to_delete) if ref_ids_to_delete.any?

          {
            query: {
              bool: {
                should: shoulds,
                minimum_should_match: 1
              }
            }
          }
        end
      end
    end
  end
end
