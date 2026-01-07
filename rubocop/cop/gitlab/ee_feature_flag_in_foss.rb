# frozen_string_literal: true

require_relative '../../code_reuse_helpers'
require_relative '../../feature_flags'

module RuboCop
  module Cop
    module Gitlab
      # Checks for usage of EE-only feature flags in FOSS code.
      #
      # Feature flags defined in ee/config/feature_flags/ should only be used
      # within the ee/ directory to prevent FOSS-only test failures.
      #
      # @example
      #
      #   # bad (in lib/gitlab/gon_helper.rb with ee/config/feature_flags/beta/ee_only_flag.yml)
      #   push_frontend_feature_flag(:ee_only_flag, current_user)
      #
      #   # good (in ee/lib/ee/gitlab/gon_helper.rb)
      #   push_frontend_feature_flag(:ee_only_flag, current_user)
      #
      #   # good (in lib/gitlab/gon_helper.rb with config/feature_flags/beta/some_flag.yml)
      #   push_frontend_feature_flag(:some_flag, current_user)
      #
      class EeFeatureFlagInFoss < RuboCop::Cop::Base
        include RuboCop::CodeReuseHelpers

        MSG = 'Feature flag `%{flag}` is defined in `ee/config/feature_flags/` but used in FOSS code. ' \
          'Move this code to the `ee/` directory or move the feature flag definition to `config/feature_flags/`.'

        RESTRICT_ON_SEND = FeatureFlags::FEATURE_METHODS + FeatureFlags::SELF_METHODS

        def on_casgn(node)
          return if in_ee?(node)

          constant_name = node.name
          rhs = node.expression

          return unless constant_name.to_s.end_with?('FEATURE_FLAG')
          return unless rhs.type?(:str, :sym)

          flag_name = rhs.value.to_s
          check_ee_feature_flag(node, flag_name)
        end

        def on_send(node)
          return if in_spec?(node)
          return if in_ee?(node)

          feature_flag_name = FeatureFlags.feature_flag_name(node)

          check_ee_feature_flag(node, feature_flag_name)
        end
        alias_method :on_csend, :on_send

        private

        def check_ee_feature_flag(node, flag_name)
          return unless ee_only_feature_flag?(flag_name)

          add_offense(node, message: format(MSG, flag: flag_name))
        end

        def ee_only_feature_flag?(flag_name)
          FeatureFlags.ee_feature_flag_names.include?(flag_name)
        end
      end
    end
  end
end
