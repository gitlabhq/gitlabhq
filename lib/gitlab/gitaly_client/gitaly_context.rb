# frozen_string_literal: true

module Gitlab
  module GitalyClient
    # A utility class that collects properties for gitaly_context into the
    # request store. The primary entrypoint is
    # `GitalyContext.with_context(&block)`, which pushes properties to the
    # context for the code within `&block`.
    class GitalyContext
      class << self
        def current_context
          instance.current_context
        end

        def with_context(**context)
          instance.with_context(**context) do
            yield
          end
        end

        private

        def instance
          Gitlab::SafeRequestStore[:gitaly_client_context] ||= new
        end
      end

      def initialize
        @stack = [{}.with_indifferent_access.freeze]
      end

      # Execute a block with the entries in `context` merged into the gitaly
      # client's context.
      def with_context(**context)
        if context <= current_context
          # no new context added
          yield
        else
          @stack << current_context.merge(context).freeze

          begin
            yield
          ensure
            @stack.pop
          end
        end
      end

      def current_context
        @stack.last
      end
    end
  end
end
