# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Gitlab
      class AvoidFeatureCategoryNotOwned < RuboCop::Cop::Base
        include ::RuboCop::CodeReuseHelpers

        MSG = 'Avoid adding new endpoints with `feature_category :not_owned`. See https://docs.gitlab.com/ee/development/feature_categorization'
        RESTRICT_ON_SEND = %i[feature_category get post put patch delete].freeze

        def_node_matcher :feature_category_not_owned?, <<~PATTERN
          (send _ :feature_category (sym :not_owned) ...)
        PATTERN

        def_node_matcher :feature_category_not_owned_api?, <<~PATTERN
          (send nil? {:get :post :put :patch :delete} _
            (hash <(pair (sym :feature_category) (sym :not_owned)) ...>)
          )
        PATTERN

        def on_send(node)
          return unless file_needs_feature_category?(node)
          return unless setting_not_owned?(node)

          add_offense(node)
        end

        private

        def file_needs_feature_category?(node)
          in_controller?(node) || in_worker?(node) || in_api?(node)
        end

        def setting_not_owned?(node)
          feature_category_not_owned?(node) || feature_category_not_owned_api?(node)
        end
      end
    end
  end
end
