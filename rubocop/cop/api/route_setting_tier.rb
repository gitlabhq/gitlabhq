# frozen_string_literal: true

module RuboCop
  module Cop
    module API
      # Checks that route_setting :tier uses valid values.
      #
      # Tier indicates which paid GitLab subscription tier an endpoint requires.
      # CE (Community Edition) endpoints are implicitly Free and should not declare a tier.
      #
      # @example
      #
      #   # bad - invalid tier value
      #   route_setting :tier, :gold
      #
      #   # bad - string instead of symbol
      #   route_setting :tier, 'premium'
      #
      #   # bad - :free is implicit; do not declare it
      #   route_setting :tier, :free
      #
      #   # good - endpoint requires Premium tier
      #   route_setting :tier, :premium
      #
      #   # good - endpoint requires Ultimate tier
      #   route_setting :tier, :ultimate
      class RouteSettingTier < RuboCop::Cop::Base
        VALID_VALUES = %i[premium ultimate].freeze

        MSG = "Invalid tier value '%<value>s'. Use :premium or :ultimate. " \
          "CE endpoints are implicitly Free and do not need a tier annotation."

        RESTRICT_ON_SEND = %i[route_setting].freeze

        # @!method tier_setting(node)
        def_node_matcher :tier_setting, <<~PATTERN
          (send nil? :route_setting (sym :tier) $_)
        PATTERN

        def on_send(node)
          tier_setting(node) do |value_node|
            next if valid_value?(value_node)

            add_offense(value_node, message: format(MSG, value: value_node.source))
          end
        end
        alias_method :on_csend, :on_send

        private

        def valid_value?(node)
          node.sym_type? && VALID_VALUES.include?(node.value)
        end
      end
    end
  end
end
