# frozen_string_literal: true

require 'rubocop/rspec/final_end_location'
require 'rubocop/rspec/blank_line_separation'
require 'rubocop/rspec/language'

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after shared example blocks.
      #
      # @example
      #   # bad
      #   RSpec.describe Foo do
      #     it_behaves_like 'do this first'
      #     it_behaves_like 'does this' do
      #     end
      #     it_behaves_like 'does that' do
      #     end
      #     it_behaves_like 'do some more'
      #   end
      #
      #   # good
      #   RSpec.describe Foo do
      #     it_behaves_like 'do this first'
      #     it_behaves_like 'does this' do
      #     end
      #
      #     it_behaves_like 'does that' do
      #     end
      #
      #     it_behaves_like 'do some more'
      #   end
      #
      #   # fair - it's ok to have non-separated without blocks
      #   RSpec.describe Foo do
      #     it_behaves_like 'do this first'
      #     it_behaves_like 'does this'
      #   end
      #
      class EmptyLineAfterSharedExample < RuboCop::Cop::Cop
        include RuboCop::RSpec::BlankLineSeparation
        include RuboCop::RSpec::Language

        MSG = 'Add an empty line after `%<example>s` block.'

        def_node_matcher :shared_examples,
                         (SharedGroups::ALL + Includes::ALL).block_pattern

        def on_block(node)
          shared_examples(node) do
            break if last_child?(node)

            missing_separating_line(node) do |location|
              add_offense(node,
                          location: location,
                          message: format(MSG, example: node.method_name))
            end
          end
        end
      end
    end
  end
end
