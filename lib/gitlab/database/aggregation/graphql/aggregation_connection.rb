# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module Graphql
        class AggregationConnection < GraphQL::Pagination::Connection
          # rubocop: disable Naming/PredicateName -- these methods are part of the GraphQL pagination API
          def has_next_page
            load_nodes
            @has_next_page
          end

          def has_previous_page
            selection_range.first > 0
          end
          # rubocop: enable Naming/PredicateName

          def cursor_for(node)
            load_nodes
            # The cursor is the absolute index: Base Offset + Index in current batch
            # We use object identity (index) to find the node in the current batch.
            batch_index = nodes.index(node)

            raise GraphQL::ExecutionError, "Node not found in current batch" unless batch_index

            encode((selection_range.first + batch_index).to_s)
          end

          def nodes
            load_nodes
          end

          private

          def load_nodes
            @nodes ||= begin
              result = @items.offset(selection_range.first).limit(selection_range.size + 1).to_a

              @has_next_page = result.size > selection_range.size

              # Remove the last element as it's only used for determining the next page
              result.pop if @has_next_page

              result
            end
          end

          def decode_cursor(cursor)
            Integer(decode(cursor)).tap do |value|
              raise GraphQL::ExecutionError, "Invalid cursor provided" if value < 0
            end
          end

          def selection_range
            @selection_range ||= begin
              # We block 'last' if 'before' is missing. This prevents us from
              # needing to know the Total Count of the underlying query.
              if last.present? && before.blank?
                raise GraphQL::ExecutionError,
                  "Argument 'last' can only be used in conjunction with 'before'."
              end

              if last.present? && first.present?
                raise GraphQL::ExecutionError, "Arguments 'last' and 'first' can't be used simultaneously."
              end

              start_index = after ? decode_cursor(after) + 1 : 0
              end_index   = before ? decode_cursor(before) - 1 : nil

              candidates = [(start_index..end_index)]

              candidates << if last # end_index is guaranteed here.
                              ((end_index - last + 1)..end_index)
                            else
                              (start_index...(start_index + first))
                            end

              candidates.min_by(&:size)
            end
          end
        end
      end
    end
  end
end
