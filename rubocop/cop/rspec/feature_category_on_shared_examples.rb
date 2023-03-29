# frozen_string_literal: true

require 'rubocop/cop/rspec/base'

module RuboCop
  module Cop
    module RSpec
      # Ensures that shared examples don't have feature category.
      #
      # @example
      #
      #   # bad
      #   RSpec.shared_examples 'an external link with rel attribute', feature_category: :team_planning do
      #   end
      #
      #   # good
      #   RSpec.shared_examples 'an external link with rel attribute' do
      #   end
      #
      #   it 'adds rel="nofollow" to external links', feature_category: :team_planning do
      #   end
      class FeatureCategoryOnSharedExamples < RuboCop::Cop::RSpec::Base
        MSG = 'Shared examples should not have feature category set'

        # @!method feature_category_value(node)
        def_node_matcher :feature_category_value, <<~PATTERN
            (block
              (send #rspec? {#SharedGroups.all} ...
                $(hash <(pair (sym :feature_category) _) ...>)
              )
            ...
            )
        PATTERN

        def on_block(node)
          value_node = feature_category_value(node)

          return unless value_node

          add_offense(value_node, message: MSG)
        end
      end
    end
  end
end
