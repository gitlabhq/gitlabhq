# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class Iterator
        UnsupportedScopeOrder = Class.new(StandardError)

        def initialize(scope:, use_union_optimization: true)
          @scope, success = Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(scope)
          raise(UnsupportedScopeOrder, 'The order on the scope does not support keyset pagination') unless success

          @order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(scope)
          @use_union_optimization = use_union_optimization
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def each_batch(of: 1000)
          cursor_attributes = {}

          loop do
            current_scope = scope.dup.limit(of)
            relation = order
              .apply_cursor_conditions(current_scope, cursor_attributes, { use_union_optimization: @use_union_optimization })
              .reorder(order)
              .limit(of)

            yield relation

            last_record = relation.last
            break unless last_record

            cursor_attributes = order.cursor_attributes_for_node(last_record)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        attr_reader :scope, :order
      end
    end
  end
end
