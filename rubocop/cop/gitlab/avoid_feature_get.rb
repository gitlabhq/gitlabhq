# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that blacklists the use of `Feature.get`.
      class AvoidFeatureGet < RuboCop::Cop::Cop
        MSG = 'Use `Feature.enable/disable` methods instead of `Feature.get`. ' \
          'See doc/development/testing_guide/best_practices.md#feature-flags-in-tests for more information.'

        def_node_matcher :feature_get?, <<~PATTERN
          (send (const nil? :Feature) :get ...)
        PATTERN

        def_node_matcher :global_feature_get?, <<~PATTERN
          (send (const (cbase) :Feature) :get ...)
        PATTERN

        def on_send(node)
          return unless feature_get?(node) || global_feature_get?(node)

          add_offense(node, location: :selector)
        end
      end
    end
  end
end
