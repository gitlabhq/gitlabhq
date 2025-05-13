# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # This cop prevents the use of Feature.enabled? and Feature.disabled? in migrations.
      # Using feature flags in migrations is forbidden to avoid breaking the migration in the future.
      # Instead, use the feature_flag_enabled?(feature_name) migration helper method.
      # https://docs.gitlab.com/development/migration_style_guide/#using-application-code-in-migrations-discouraged
      class PreventFeatureFlagsUsage < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = "Do not use Feature.enabled? or Feature.disabled? in migrations. " \
          "Use the feature_flag_enabled?(feature_name) migration helper method."

        # @!method feature_enabled?(node)
        def_node_matcher :feature_enabled?, <<~PATTERN
          (send (const nil? :Feature) :enabled? ...)
        PATTERN

        # @!method feature_disabled?(node)
        def_node_matcher :feature_disabled?, <<~PATTERN
          (send (const nil? :Feature) :disabled? ...)
        PATTERN

        def on_def(node)
          return unless in_migration?(node)

          node.each_descendant(:send) do |send_node|
            add_offense(send_node) if feature_enabled?(send_node) || feature_disabled?(send_node)
          end
        end
      end
    end
  end
end
