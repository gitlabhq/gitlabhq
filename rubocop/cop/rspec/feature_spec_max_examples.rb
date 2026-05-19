# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # Limits the number of examples in feature spec files.
      #
      # Feature specs with too many examples are slow to run, hard to maintain,
      # and often indicate the file should be split into smaller, focused specs.
      #
      # The maximum number of examples can be configured with the `Max` option
      # (default: 25).
      #
      # @example Max: 25 (default)
      #
      #   # bad
      #   # A feature spec file with more than 25 examples.
      #
      #   # good
      #   # A feature spec file with 25 or fewer examples.
      class FeatureSpecMaxExamples < RuboCop::Cop::RSpec::Base
        MSG = 'Feature spec file has %<count>d examples, which exceeds the maximum of %<max>d. ' \
          'Consider splitting into smaller, focused files grouped by user flow or feature area.'

        def on_new_investigation
          super
          @example_count = 0
          @top_level_describe = nil
        end

        def on_block(node)
          @top_level_describe ||= node if example_group?(node)
          @example_count += 1 if example?(node)
        end
        alias_method :on_numblock, :on_block

        def on_investigation_end
          max = cop_config['Max'] || 25
          return if @example_count <= max
          return unless @top_level_describe

          add_offense(@top_level_describe.send_node,
            message: format(MSG, count: @example_count, max: max))
        end
      end
    end
  end
end
