# frozen_string_literal: true

require_relative '../../migration_helpers'
require_relative '../../code_reuse_helpers'
require_relative '../../feature_categories'

module RuboCop
  module Cop
    module BackgroundMigration
      # Cop that checks if a valid 'feature_category' is defined in the batched background migration job
      class FeatureCategory < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = "'feature_category' should be defined to better assign the ownership for batched migration jobs. " \
              "For more details refer: " \
              "https://docs.gitlab.com/ee/development/feature_categorization/#batched-background-migrations"

        INVALID_FEATURE_CATEGORY_MSG =
          "'feature_category' is invalid. " \
          "List of valid ones can be found in #{FeatureCategories::CONFIG_PATH}".freeze

        RESTRICT_ON_SEND = [:feature_category].freeze

        def_node_search :feature_category?, <<~PATTERN
          (:send nil? :feature_category ...)
        PATTERN

        def on_class(node)
          return unless in_background_migration?(node) && node.parent_class&.short_name == :BatchedMigrationJob

          add_offense(node) unless feature_category?(node)
        end

        def on_send(node)
          return unless in_background_migration?(node)

          add_offense(node, message: INVALID_FEATURE_CATEGORY_MSG) unless valid_feature_category?(node)
        end

        def external_dependency_checksum
          FeatureCategories.config_checksum
        end

        private

        def valid_feature_category?(node)
          feature_category = node.descendants.first.value
          FeatureCategories.available.include?(feature_category.to_s)
        end
      end
    end
  end
end
