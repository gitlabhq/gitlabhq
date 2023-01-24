# frozen_string_literal: true

require 'rubocop/cop/rspec/base'
require 'rubocop/cop/rspec/mixin/top_level_group'

module RuboCop
  module Cop
    module RSpec
      # Ensures that top level example group contains a feature category.
      #
      # @example
      #
      #   # bad
      #   RSpec.describe 'foo' do
      #   end
      #
      #   # good
      #   RSpec.describe 'foo', feature_category: :wiki do
      #   end
      class MissingFeatureCategory < RuboCop::Cop::RSpec::Base
        include RuboCop::Cop::RSpec::TopLevelGroup

        MSG = 'Please add missing feature category. ' \
              'See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples.'

        # @!method feature_category?(node)
        def_node_matcher :feature_category?, <<~PATTERN
            (block
              (send ...
                (hash <(pair (sym :feature_category) _) ...>)
              )
              ...
            )
        PATTERN

        def on_top_level_example_group(node)
          return if feature_category?(node)

          add_offense(node.children.first)
        end
      end
    end
  end
end
