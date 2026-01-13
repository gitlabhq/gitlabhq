# frozen_string_literal: true

require_relative '../../code_reuse_helpers'
require_relative '../../feature_flags'

module RuboCop
  module Cop
    module Gitlab
      # This cop tracks the usage of feature flags among the codebase.
      #
      # The files set in `tmp/feature_flags/*.used` can then be used for verification purpose.
      #
      class MarkUsedFeatureFlags < RuboCop::Cop::Base
        include RuboCop::CodeReuseHelpers

        RESTRICT_ON_SEND = FeatureFlags::FEATURE_METHODS + FeatureFlags::SELF_METHODS

        class << self
          # We track feature flags in `on_new_investigation` only once per
          # rubocop whole run instead once per file.
          attr_accessor :feature_flags_already_tracked
        end

        # Called before all on_... have been called
        # When refining this method, always call `super`
        def on_new_investigation
          super

          return if self.class.feature_flags_already_tracked

          self.class.feature_flags_already_tracked = true
        end

        def on_casgn(node)
          _, lhs_name, rhs = *node

          save_used_feature_flag(rhs.value) if lhs_name.to_s.end_with?('FEATURE_FLAG')
        end

        def on_send(node)
          return if in_spec?(node)

          feature_flag_name = FeatureFlags.feature_flag_name(node)
          save_used_feature_flag(feature_flag_name) if feature_flag_name

          FeatureFlags.dynamic_feature_flag_names(node).each do |feature_flag_name|
            save_used_feature_flag(feature_flag_name)
          end
        end

        private

        def save_used_feature_flag(feature_flag_name)
          used_feature_flag_file = File.expand_path("../../../tmp/feature_flags/#{feature_flag_name}.used", __dir__)
          return if File.exist?(used_feature_flag_file)

          FileUtils.touch(used_feature_flag_file)
        end
      end
    end
  end
end
