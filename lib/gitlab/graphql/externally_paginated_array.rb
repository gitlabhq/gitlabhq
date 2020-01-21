# frozen_string_literal: true

module Gitlab
  module Graphql
    class ExternallyPaginatedArray < Array
      attr_reader :previous_cursor, :next_cursor

      def initialize(previous_cursor, next_cursor, *args)
        super(args)
        @previous_cursor = previous_cursor
        @next_cursor = next_cursor
      end
    end
  end
end
