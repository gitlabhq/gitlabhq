# frozen_string_literal: true

module Gitlab
  module Graphql
    class Lazy
      include Gitlab::Utils::StrongMemoize

      def initialize(&block)
        @proc = block
      end

      def force
        strong_memoize(:force) { self.class.force(@proc.call) }
      end

      def then(&block)
        self.class.new { yield force }
      end

      # Force evaluation of a (possibly) lazy value
      def self.force(value)
        case value
        when ::Gitlab::Graphql::Lazy
          value.force
        when ::BatchLoader::GraphQL
          value.sync
        when ::GraphQL::Execution::Lazy
          value.value # part of the private api, but we can force this as well
        when ::Concurrent::Promise
          value.execute if value.state == :unscheduled

          value.value # value.value(10.seconds)
        else
          value
        end
      end

      def self.with_value(unforced, &block)
        self.new { unforced }.then(&block)
      end
    end
  end
end
