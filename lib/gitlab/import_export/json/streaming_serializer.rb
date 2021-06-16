# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Json
      class StreamingSerializer
        include Gitlab::ImportExport::CommandLineUtil

        BATCH_SIZE = 100
        SMALLER_BATCH_SIZE = 2

        def self.batch_size(exportable)
          if Feature.enabled?(:export_reduce_relation_batch_size, exportable)
            SMALLER_BATCH_SIZE
          else
            BATCH_SIZE
          end
        end

        class Raw < String
          def to_json(*_args)
            to_s
          end
        end

        def initialize(exportable, relations_schema, json_writer, exportable_path:)
          @exportable = exportable
          @exportable_path = exportable_path
          @relations_schema = relations_schema
          @json_writer = json_writer
        end

        def execute
          serialize_root

          includes.each do |relation_definition|
            serialize_relation(relation_definition)
          end
        end

        def serialize_relation(definition)
          raise ArgumentError, 'definition needs to be Hash' unless definition.is_a?(Hash)
          raise ArgumentError, 'definition needs to have exactly one Hash element' unless definition.one?

          key, options = definition.first

          record = exportable.public_send(key) # rubocop: disable GitlabSecurity/PublicSend
          if record.is_a?(ActiveRecord::Relation)
            serialize_many_relations(key, record, options)
          elsif record.respond_to?(:each) # this is to support `project_members` that return an Array
            serialize_many_each(key, record, options)
          else
            serialize_single_relation(key, record, options)
          end
        end

        private

        attr_reader :json_writer, :relations_schema, :exportable

        def serialize_root
          attributes = exportable.as_json(
            relations_schema.merge(include: nil, preloads: nil))
          json_writer.write_attributes(@exportable_path, attributes)
        end

        def serialize_many_relations(key, records, options)
          enumerator = Enumerator.new do |items|
            key_preloads = preloads&.dig(key)

            batch(records, key) do |batch|
              batch = batch.preload(key_preloads) if key_preloads

              batch.each do |record|
                items << Raw.new(record.to_json(options))
              end
            end
          end

          json_writer.write_relation_array(@exportable_path, key, enumerator)
        end

        def batch(relation, key)
          opts = { of: batch_size }
          order_by = reorders(relation, key)

          # we need to sort issues by non primary key column(relative_position)
          # and `in_batches` does not support that
          if order_by
            scope = relation.reorder(order_by)

            Gitlab::Pagination::Keyset::Iterator.new(scope: scope, use_union_optimization: true).each_batch(**opts) do |batch|
              yield batch
            end
          else
            relation.in_batches(**opts) do |batch| # rubocop:disable Cop/InBatches
              # order each batch by its primary key to ensure
              # consistent and predictable ordering of each exported relation
              # as additional `WHERE` clauses can impact the order in which data is being
              # returned by database when no `ORDER` is specified
              yield batch.reorder(batch.klass.primary_key)
            end
          end
        end

        def serialize_many_each(key, records, options)
          enumerator = Enumerator.new do |items|
            records.each do |record|
              items << Raw.new(record.to_json(options))
            end
          end

          json_writer.write_relation_array(@exportable_path, key, enumerator)
        end

        def serialize_single_relation(key, record, options)
          json = Raw.new(record.to_json(options))

          json_writer.write_relation(@exportable_path, key, json)
        end

        def includes
          relations_schema[:include]
        end

        def preloads
          relations_schema[:preload]
        end

        def batch_size
          @batch_size ||= self.class.batch_size(@exportable)
        end

        def reorders(relation, key)
          export_reorder = relations_schema[:export_reorder]&.dig(key)
          return unless export_reorder

          custom_reorder(relation.klass, export_reorder)
        end

        def custom_reorder(klass, order_by)
          arel_table = klass.arel_table
          column = order_by[:column] || klass.primary_key
          direction = order_by[:direction] || :asc
          nulls_position = order_by[:nulls_position] || :nulls_last

          arel_order_classes = ::Gitlab::Pagination::Keyset::ColumnOrderDefinition::AREL_ORDER_CLASSES.invert
          reverse_direction = ::Gitlab::Pagination::Keyset::ColumnOrderDefinition::REVERSED_ORDER_DIRECTIONS[direction]
          reverse_nulls_position = ::Gitlab::Pagination::Keyset::ColumnOrderDefinition::REVERSED_NULL_POSITIONS[nulls_position]
          order_expression = ::Gitlab::Database.nulls_order(column, direction, nulls_position)
          reverse_order_expression = ::Gitlab::Database.nulls_order(column, reverse_direction, reverse_nulls_position)

          ::Gitlab::Pagination::Keyset::Order.build([
            ::Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: column,
              column_expression: arel_table[column],
              order_expression: order_expression,
              reversed_order_expression: reverse_order_expression,
              order_direction: direction,
              nullable: nulls_position,
              distinct: false
            ),
            ::Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: klass.primary_key,
              order_expression: arel_order_classes[direction].new(arel_table[klass.primary_key.to_sym])
            )
          ])
        end
      end
    end
  end
end
