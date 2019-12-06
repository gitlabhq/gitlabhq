# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      # A Page models the pagination information for a particular page of the collection
      class Page
        # Default number of records for a page
        DEFAULT_PAGE_SIZE = 20

        # Maximum number of records for a page
        MAXIMUM_PAGE_SIZE = 100

        attr_accessor :lower_bounds, :end_reached
        attr_reader :order_by

        def initialize(order_by: {}, lower_bounds: nil, per_page: DEFAULT_PAGE_SIZE, end_reached: false)
          @order_by = order_by.symbolize_keys
          @lower_bounds = lower_bounds&.symbolize_keys
          @per_page = per_page
          @end_reached = end_reached
        end

        # Number of records to return per page
        def per_page
          return DEFAULT_PAGE_SIZE if @per_page <= 0

          [@per_page, MAXIMUM_PAGE_SIZE].min
        end

        # Determine whether this page indicates the end of the collection
        def end_reached?
          @end_reached
        end

        # Construct a Page for the next page
        # Uses identical order_by/per_page information for the next page
        def next(lower_bounds, end_reached)
          dup.tap do |next_page|
            next_page.lower_bounds = lower_bounds&.symbolize_keys
            next_page.end_reached = end_reached
          end
        end
      end
    end
  end
end
