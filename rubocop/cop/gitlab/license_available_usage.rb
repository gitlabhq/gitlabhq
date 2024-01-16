# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop to ban use of License.feature_available? in ApplicationSetting model to avoid cyclical dependency issues.
      # Issue example: https://gitlab.com/gitlab-org/gitlab/-/issues/423237
      class LicenseAvailableUsage < RuboCop::Cop::Base
        MSG = 'Avoid License.feature_available? usage in ApplicationSetting due to possible cyclical dependency ' \
              'issue. For more information see: https://gitlab.com/gitlab-org/gitlab/-/issues/423237'

        RESTRICT_ON_SEND = [:feature_available?].freeze

        def_node_matcher :license_feature_available?, <<~PATTERN
          (send
            (const nil? :License) :feature_available?
            (sym $_))
        PATTERN

        def on_send(node)
          add_offense(node, message: MSG) if license_feature_available?(node)
        end
      end
    end
  end
end
