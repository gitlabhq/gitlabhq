# frozen_string_literal: true

module RuboCop
  module Cop
    class FeatureFlagUsage < RuboCop::Cop::Base
      MSG = 'Do not use Feature Flags for monkey-patches or Redis code. Use environment variables instead.'

      def_node_matcher :using_feature_flag?, <<~PATTERN
        (send (const {nil? | cbase} :Feature) {:enabled? | :disabled?} ...)
      PATTERN

      def on_send(node)
        return unless using_feature_flag?(node)

        add_offense(node, message: MSG)
      end
    end
  end
end
