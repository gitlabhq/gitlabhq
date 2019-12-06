# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class Pager
        attr_reader :request

        def initialize(request)
          @request = request
        end

        def paginate(relation)
          # Validate assumption: The last two columns must match the page order_by
          validate_order!(relation)

          # This performs the database query and retrieves records
          # We retrieve one record more to check if we have data beyond this page
          all_records = relation.limit(page.per_page + 1).to_a # rubocop: disable CodeReuse/ActiveRecord

          records_for_page = all_records.first(page.per_page)

          # If we retrieved more records than belong on this page,
          # we know there's a next page
          there_is_more = all_records.size > records_for_page.size
          apply_headers(records_for_page.last, there_is_more)

          records_for_page
        end

        private

        def apply_headers(last_record_in_page, there_is_more)
          end_reached = last_record_in_page.nil? || !there_is_more
          lower_bounds = last_record_in_page&.slice(page.order_by.keys)

          next_page = page.next(lower_bounds, end_reached)

          request.apply_headers(next_page)
        end

        def page
          @page ||= request.page
        end

        def validate_order!(rel)
          present_order = rel.order_values.map { |val| [val.expr.name.to_sym, val.direction] }.last(2).to_h

          unless page.order_by == present_order
            raise ArgumentError, "Page's order_by does not match the relation's order: #{present_order} vs #{page.order_by}"
          end
        end
      end
    end
  end
end
