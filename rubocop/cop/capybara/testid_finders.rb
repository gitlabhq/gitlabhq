# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module Capybara
      # Prefer to use data-testid helpers for Capybara
      #
      # @example
      #   # bad
      #   find('[data-testid="some-testid"]')
      #   within('[data-testid="some-testid"]')
      #
      #   # good
      #   find_by_testid('some-testid')
      #   within_testid('some-testid')
      #
      class TestidFinders < RuboCop::Cop::Base
        MSG = 'Prefer to use custom helper method `%{replacement}(%{testid})`.'

        METHOD_MAP = {
          find: 'find_by_testid',
          within: 'within_testid'
        }.freeze

        RESTRICT_ON_SEND = METHOD_MAP.keys.to_set.freeze

        # @!method find_argument(node)
        def_node_matcher :argument, <<~PATTERN
          (send _ ${RESTRICT_ON_SEND} (str $_) ...)
        PATTERN

        def on_send(node)
          argument(node) do |method, arg|
            selector = data_testid_selector(arg)
            next unless selector

            replacement = METHOD_MAP.fetch(method)
            msg = format(MSG, testid: selector, replacement: replacement)

            add_offense(node, message: msg)
          end
        end

        private

        def data_testid_selector(arg)
          arg[/^\[data-testid=[",'](.+)[",']\]$/, 1]
        end
      end
    end
  end
end
