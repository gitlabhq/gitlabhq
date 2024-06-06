# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # This cop checks for `Sidekiq::Testing.server_middleware`
      # usage in specs.
      #
      # @example
      #
      #   # bad
      #   Sidekiq::Testing.server_middleware do |chain|
      #     chain.add(MyMiddlewareUnderTest)
      #   end
      #
      #
      #   # good
      #   with_custom_sidekiq_middleware do |chain|
      #     chain.add(MyMiddlewareUnderTest)
      #   end
      #
      #
      class ModifySidekiqMiddleware < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = <<~MSG
          Don't modify global sidekiq middleware, use the `#with_sidekiq_server_middleware`
          helper instead
        MSG

        def_node_search :modifies_sidekiq_middleware?, <<~PATTERN
          (send
            (const
              (const nil? :Sidekiq) :Testing) :server_middleware)
        PATTERN

        def on_send(node)
          return unless modifies_sidekiq_middleware?(node)

          add_offense(node) do |corrector|
            corrector.replace(node.loc.expression,
              'with_sidekiq_server_middleware')
          end
        end
      end
    end
  end
end
