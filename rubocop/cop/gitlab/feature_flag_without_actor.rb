# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class FeatureFlagWithoutActor < RuboCop::Cop::Base
        MSG = 'Do not use feature flags without an explicit actor. See https://docs.gitlab.com/ee/development/feature_flags/#feature-actors'

        def_node_matcher :using_feature_flag_without_actor?, <<~PATTERN
          (send
            (const {nil? cbase} :Feature)
            {:enabled? :disabled?}
            _key
            (hash ...)?
          )
        PATTERN

        def on_send(node)
          return unless using_feature_flag_without_actor?(node)

          add_offense(node, message: MSG)
        end
      end
    end
  end
end
