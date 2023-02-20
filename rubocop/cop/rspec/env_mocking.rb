# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # Check for ENV mocking in specs.
      # See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#persistent-in-memory-application-state
      #
      # @example
      #
      #   # bad
      #   allow(ENV).to receive(:[]).with('FOO').and_return('bar')
      #   allow(ENV).to receive(:fetch).with('FOO').and_return('bar')
      #   allow(ENV).to receive(:[]).with(key).and_return(value)
      #   allow(ENV).to receive(:[]).with(fetch_key(object)).and_return(fetch_value(object))
      #
      #   # good
      #   stub_env('FOO', 'bar')
      #   stub_env(key, value)
      #   stub_env(fetch_key(object), fetch_value(object))
      class EnvMocking < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MESSAGE = "Don't mock the ENV, use `stub_env` instead."

        def_node_matcher :env_mocking?, <<~PATTERN
        (send
          (send nil? :allow
            (const {nil? cbase} :ENV)
          )
          :to
          (send
            (send
              (send nil? :receive (sym {:[] :fetch}))
              :with $_
            )
            :and_return $_
          )
          ...
        )
        PATTERN

        def on_send(node)
          env_mocking?(node) do |key, value|
            add_offense(node, message: MESSAGE) do |corrector|
              corrector.replace(node.loc.expression, stub_env(key.source, value.source))
            end
          end
        end

        def stub_env(key, value)
          "stub_env(#{key}, #{value})"
        end
      end
    end
  end
end
