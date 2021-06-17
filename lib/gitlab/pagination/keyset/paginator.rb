# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class Paginator
        include Enumerable

        module Base64CursorConverter
          def self.dump(cursor_attributes)
            Base64.urlsafe_encode64(Gitlab::Json.dump(cursor_attributes))
          end

          def self.parse(cursor)
            Gitlab::Json.parse(Base64.urlsafe_decode64(cursor)).with_indifferent_access
          end
        end

        FORWARD_DIRECTION = 'n'
        BACKWARD_DIRECTION = 'p'

        UnsupportedScopeOrder = Class.new(StandardError)

        # scope                  - ActiveRecord::Relation object with order by clause
        # cursor                 - Encoded cursor attributes as String. Empty value will requests the first page.
        # per_page               - Number of items per page.
        # cursor_converter       - Object that serializes and de-serializes the cursor attributes. Implements dump and parse methods.
        # direction_key          - Symbol that will be the hash key of the direction within the cursor. (default: _kd => keyset direction)
        def initialize(scope:, cursor: nil, per_page: 20, cursor_converter: Base64CursorConverter, direction_key: :_kd, keyset_order_options: {})
          @keyset_scope = build_scope(scope)
          @order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(@keyset_scope)
          @per_page = per_page
          @cursor_converter = cursor_converter
          @direction_key = direction_key
          @has_another_page = false
          @at_last_page = false
          @at_first_page = false
          @cursor_attributes = decode_cursor_attributes(cursor)
          @keyset_order_options = keyset_order_options

          set_pagination_helper_flags!
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def records
          @records ||= begin
            items = if paginate_backward?
                      reversed_order
                        .apply_cursor_conditions(keyset_scope, cursor_attributes, keyset_order_options)
                        .reorder(reversed_order)
                        .limit(per_page_plus_one)
                        .to_a
                    else
                      order
                        .apply_cursor_conditions(keyset_scope, cursor_attributes, keyset_order_options)
                        .limit(per_page_plus_one)
                        .to_a
                    end

            @has_another_page = items.size == per_page_plus_one
            items.pop if @has_another_page
            items.reverse! if paginate_backward?
            items
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # This and has_previous_page? methods are direction aware. In case we paginate backwards,
        # has_next_page? will mean that we have a previous page.
        def has_next_page?
          records

          if at_last_page?
            false
          elsif paginate_forward?
            @has_another_page
          elsif paginate_backward?
            true
          end
        end

        def has_previous_page?
          records

          if at_first_page?
            false
          elsif paginate_backward?
            @has_another_page
          elsif paginate_forward?
            true
          end
        end

        def cursor_for_next_page
          if has_next_page?
            data = order.cursor_attributes_for_node(records.last)
            data[direction_key] = FORWARD_DIRECTION
            cursor_converter.dump(data)
          else
            nil
          end
        end

        def cursor_for_previous_page
          if has_previous_page?
            data = order.cursor_attributes_for_node(records.first)
            data[direction_key] = BACKWARD_DIRECTION
            cursor_converter.dump(data)
          end
        end

        def cursor_for_first_page
          cursor_converter.dump({ direction_key => FORWARD_DIRECTION })
        end

        def cursor_for_last_page
          cursor_converter.dump({ direction_key => BACKWARD_DIRECTION })
        end

        delegate :each, :empty?, :any?, to: :records

        private

        attr_reader :keyset_scope, :order, :per_page, :cursor_converter, :direction_key, :cursor_attributes, :keyset_order_options

        delegate :reversed_order, to: :order

        def at_last_page?
          @at_last_page
        end

        def at_first_page?
          @at_first_page
        end

        def per_page_plus_one
          per_page + 1
        end

        def decode_cursor_attributes(cursor)
          cursor.blank? ? {} : cursor_converter.parse(cursor)
        end

        def set_pagination_helper_flags!
          @direction = cursor_attributes.delete(direction_key.to_s)

          if cursor_attributes.blank? && @direction.blank?
            @at_first_page = true
            @direction = FORWARD_DIRECTION
          elsif cursor_attributes.blank?
            if paginate_forward?
              @at_first_page = true
            else
              @at_last_page = true
            end
          end
        end

        def paginate_backward?
          @direction == BACKWARD_DIRECTION
        end

        def paginate_forward?
          @direction == FORWARD_DIRECTION
        end

        def build_scope(scope)
          keyset_aware_scope, success = Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(scope)

          raise(UnsupportedScopeOrder, 'The order on the scope does not support keyset pagination') unless success

          keyset_aware_scope
        end
      end
    end
  end
end
