# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Bans the use of `Feature.get`.
      #
      # @example
      #
      # # bad
      #
      # Feature.get(:x)
      #
      # # good
      #
      # stub_feature_flags(x: true)
      #
      class AvoidFeatureGet < RuboCop::Cop::Cop
        MSG = 'Use `stub_feature_flags` method instead of `Feature.get`. ' \
          'See doc/development/feature_flags/index.md#feature-flags-in-tests for more information.'

        def_node_matcher :feature_get?, <<~PATTERN
          (send (const {nil? cbase} :Feature) :get ...)
        PATTERN

        def on_send(node)
          return unless feature_get?(node)

          add_offense(node, location: :selector)
        end
      end
    end
  end
end
