# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # This cop checks for ENV assignment in specs
      #
      # @example
      #
      #   # bad
      #   before do
      #     ENV['FOO'] = 'bar'
      #   end
      #
      #   # good
      #   before do
      #     stub_env('FOO', 'bar')
      #   end
      class EnvAssignment < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MESSAGE = "Don't assign to ENV, use `stub_env` instead."

        def_node_search :env_assignment?, <<~PATTERN
          (send (const nil? :ENV) :[]= ...)
        PATTERN

        # Following is what node.children looks like on a match
        # [s(:const, nil, :ENV), :[]=, s(:str, "key"), s(:str, "value")]
        def on_send(node)
          return unless env_assignment?(node)

          add_offense(node, message: MESSAGE) do |corrector|
            corrector.replace(node.loc.expression, stub_env(env_key(node), env_value(node)))
          end
        end

        def env_key(node)
          node.children[2].source
        end

        def env_value(node)
          node.children[3].source
        end

        def stub_env(key, value)
          "stub_env(#{key}, #{value})"
        end
      end
    end
  end
end
