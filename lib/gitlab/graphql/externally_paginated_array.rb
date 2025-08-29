# frozen_string_literal: true

module Gitlab
  module Graphql
    class ExternallyPaginatedArray < Array
      attr_reader :start_cursor, :end_cursor, :has_next_page, :has_previous_page

      def initialize(previous_cursor, next_cursor, *args, has_next_page: nil, has_previous_page: nil)
        super(args)
        @start_cursor = previous_cursor
        @end_cursor = next_cursor
        @has_next_page = has_next_page
        @has_previous_page = has_previous_page
      end
    end
  end
end
