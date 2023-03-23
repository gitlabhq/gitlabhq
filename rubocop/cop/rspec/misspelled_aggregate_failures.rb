# frozen_string_literal: true

require 'rubocop/cop/rspec/base'

module RuboCop
  module Cop
    module RSpec
      class MisspelledAggregateFailures < RuboCop::Cop::RSpec::Base
        extend RuboCop::Cop::AutoCorrector

        CORRECT_SPELLING = :aggregate_failures
        MSG = "Use `#{CORRECT_SPELLING.inspect}` to aggregate failures.".freeze

        # @!method aggregate_tag(node)
        def_node_matcher :aggregate_tag, <<~PATTERN
          (block
            (send #rspec? {#ExampleGroups.all #Examples.all}
              <$(sym /^aggregate[a-z]*_[a-z]+$/) ...>
            )
            ...
          )
        PATTERN

        def on_block(node)
          tag_node = aggregate_tag(node)
          return if tag_node.nil? || tag_node.value == CORRECT_SPELLING

          add_offense(tag_node) do |corrector|
            corrector.replace(tag_node, CORRECT_SPELLING.inspect)
          end
        end
      end
    end
  end
end
