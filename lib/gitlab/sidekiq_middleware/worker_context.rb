# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module WorkerContext
      private

      def wrap_in_optional_context(context_or_nil, &block)
        return yield unless context_or_nil

        context_or_nil.use(&block)
      end
    end
  end
end
