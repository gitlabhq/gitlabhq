# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class Iterator
        def initialize(scope:, cursor: {}, use_union_optimization: true, in_operator_optimization_options: nil)
          @scope, success = Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(scope)
          raise(UnsupportedScopeOrder) unless success

          @cursor = cursor
          @order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(@scope)
          @use_union_optimization = in_operator_optimization_options ? false : use_union_optimization
          @in_operator_optimization_options = in_operator_optimization_options
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def each_batch(of: 1000, load_batch: true)
          loop do
            current_scope = scope.dup
            relation = order.apply_cursor_conditions(current_scope, cursor, keyset_options)
            relation = relation.reorder(order) unless @in_operator_optimization_options
            relation = relation.limit(of)

            if load_batch
              last_record = relation.last
              break unless last_record

              yield relation
            else
              last_record, next_record = relation.offset(of - 1).limit(2)
              yield relation

              break unless next_record
            end

            @cursor = order.cursor_attributes_for_node(last_record)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        attr_reader :scope, :cursor, :order

        def keyset_options
          {
            use_union_optimization: @use_union_optimization,
            in_operator_optimization_options: @in_operator_optimization_options
          }
        end
      end
    end
  end
end
