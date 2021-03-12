# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      module Keyset
        # This class handles the last(N) ActiveRecord call even if a special ORDER BY configuration is present.
        # For the last(N) call, ActiveRecord calls reverse_order, however for some cases it raises
        # ActiveRecord::IrreversibleOrderError error.
        class LastItems
          # rubocop: disable CodeReuse/ActiveRecord
          def self.take_items(scope, count)
            if Gitlab::Pagination::Keyset::Order.keyset_aware?(scope)
              order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(scope)
              items = scope.reorder(order.reversed_order).first(count)
              items.is_a?(Array) ? items.reverse : items
            else
              scope.last(count)
            end
          end
        end
      end
    end
  end
end
