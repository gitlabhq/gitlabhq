# frozen_string_literal: true

module Gitlab
  module Graphql
    class FilterableArray < Array
      attr_reader :filter_callback

      def initialize(filter_callback, *args)
        super(args)
        @filter_callback = filter_callback
      end
    end
  end
end
