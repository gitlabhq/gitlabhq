# frozen_string_literal: true

require 'rubocop/cop/rspec/base'

module RuboCop
  module Cop
    module RSpec
      # Ensures that shared examples and shared context don't have any metadata.
      #
      # @example
      #
      #   # bad
      #   RSpec.shared_examples 'an external link with rel attribute', feature_category: :team_planning do
      #   end
      #
      #   RSpec.shared_examples 'an external link with rel attribute', :aggregate_failures do
      #   end
      #
      #   RSpec.shared_context 'an external link with rel attribute', :aggregate_failures do
      #   end
      #
      #   # good
      #   RSpec.shared_examples 'an external link with rel attribute' do
      #   end
      #
      #   shared_examples 'an external link with rel attribute' do
      #   end
      #
      #   it 'adds rel="nofollow" to external links', feature_category: :team_planning do
      #   end
      class SharedGroupsMetadata < RuboCop::Cop::RSpec::Base
        MSG = 'Avoid using metadata on shared examples and shared context. They might cause flaky tests. See https://gitlab.com/gitlab-org/gitlab/-/issues/404388'

        # @!method metadata_value(node)
        def_node_matcher :metadata_value, <<~PATTERN
            (block
              (send #rspec? {#SharedGroups.all} _description $_ ...)
            ...
            )
        PATTERN

        def on_block(node)
          value_node = metadata_value(node)

          return unless value_node

          add_offense(value_node, message: MSG)
        end
      end
    end
  end
end
