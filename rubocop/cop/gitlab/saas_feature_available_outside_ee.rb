# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Checks for use of Gitlab::Saas.feature_available? outside of the /ee directory.
      #
      # @example
      #
      #   # bad (outside /ee directory)
      #   if Gitlab::Saas.feature_available?(:some_feature)
      #     # do something
      #   end
      #
      #   # bad (outside /ee directory with safe navigation)
      #   if Gitlab::Saas&.feature_available?(:some_feature)
      #     # do something
      #   end
      #
      #   # good (inside /ee directory)
      #   if Gitlab::Saas.feature_available?(:some_feature)
      #     # do something
      #   end
      #
      class SaasFeatureAvailableOutsideEe < RuboCop::Cop::Base
        MSG = 'Gitlab::Saas.feature_available? should only be used within the /ee directory. ' \
          'See https://docs.gitlab.com/development/ee_features/#do-not-use-saas-only-features-for-functionality-in-ce.'

        RESTRICT_ON_SEND = %i[feature_available?].freeze

        # @!method saas_feature_available?(node)
        def_node_matcher :saas_feature_available?, <<~PATTERN
          (call
            (const
              (const
                {nil? (cbase)} :Gitlab) :Saas) :feature_available? ...)
        PATTERN

        def on_send(node)
          check_saas_feature_available(node)
        end
        alias_method :on_csend, :on_send

        private

        def check_saas_feature_available(node)
          return unless saas_feature_available?(node)

          add_offense(node)
        end
      end
    end
  end
end
