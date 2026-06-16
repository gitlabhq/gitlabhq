# frozen_string_literal: true

module Gitlab
  module Database
    module Batch
      # Wraps Pagination::Keyset::Iterator for callers whose seeded cursor must be treated as
      # inclusive (>= start_cursor) on the first batch, then strict (> prev_end) on subsequent
      # batches.
      #
      # The standard Iterator emits strict `>` for any seeded cursor. That's correct for keyset
      # pagination (the seed sits before the next page), but not for callers like cursor-based
      # batched background migrations where `start_cursor` is the first row to include.
      #
      # Leaving `>= start_cursor` in the scope while the Iterator adds `> prev_end` on top causes
      # Postgres to apply only one row-constructor predicate as the B-tree index range and the
      # other as a filter, re-scanning each sub-batch from start_cursor (#599681).
      #
      # This wrapper runs the first sub-batch as a one-shot inclusive query, then hands phase 2
      # off to a vanilla Iterator seeded with phase 1's last row.
      class InclusiveCursorIterator
        def initialize(scope:, cursor_columns:, start_cursor:)
          raise ArgumentError, 'cursor_columns must not be empty' if cursor_columns.blank?

          if start_cursor.blank? || start_cursor.size != cursor_columns.size
            raise ArgumentError, "start_cursor (#{start_cursor.inspect}) must have one value " \
              "per cursor column (#{cursor_columns.inspect})"
          end

          @scope, success = Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(scope)
          raise Gitlab::Pagination::Keyset::UnsupportedScopeOrder unless success

          @order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(@scope)
          @cursor_columns = cursor_columns
          @start_cursor = start_cursor
        end

        # rubocop: disable CodeReuse/ActiveRecord -- builds keyset where-clause inline
        def each_batch(of: 1000, load_batch: false)
          first_batch = scope.where(inclusive_start_predicate).limit(of)

          # Matches Pagination::Keyset::Iterator's `load_batch: false` semantics: peek with offset
          # to detect "is there more after this batch", yield the relation (even if empty), then
          # continue to phase 2 only if more rows exist.
          last_record, next_record = first_batch.offset(of - 1).limit(2)
          yield first_batch
          return unless next_record

          Gitlab::Pagination::Keyset::Iterator.new(
            scope: scope,
            cursor: order.cursor_attributes_for_node(last_record)
          ).each_batch(of: of, load_batch: load_batch) do |sub_batch|
            yield sub_batch
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        attr_reader :scope, :order, :cursor_columns, :start_cursor

        def inclusive_start_predicate
          arel_table = scope.klass.arel_table

          cursor_expression = Arel::Nodes::Grouping.new(
            cursor_columns.map { |column| arel_table[column] }
          )
          start_cursor_values = Arel::Nodes::Grouping.new(
            cursor_columns.zip(start_cursor).map do |column, value|
              Arel::Nodes.build_quoted(value, arel_table[column])
            end
          )

          cursor_expression.gteq(start_cursor_values)
        end
      end
    end
  end
end
