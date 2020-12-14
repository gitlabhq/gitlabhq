# frozen_string_literal: true

module Gitlab
  module Graphql
    class ExternallyPaginatedArray < Array
      attr_reader :start_cursor, :end_cursor

      def initialize(previous_cursor, next_cursor, *args)
        super(args)
        @start_cursor = previous_cursor
        @end_cursor = next_cursor
      end
    end
  end
end
