# frozen_string_literal: true

require_relative '../../migration_helpers'
require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module BackgroundMigration
      # Cop that checks if a valid 'feature_category' is defined in the batched background migration job
      class FeatureCategory < RuboCop::Cop::Base
        include MigrationHelpers

        FEATURE_CATEGORIES_FILE_PATH = "config/feature_categories.yml"

        MSG = "'feature_category' should be defined to better assign the ownership for batched migration jobs. " \
              "For more details refer: " \
              "https://docs.gitlab.com/ee/development/feature_categorization/#batched-background-migrations"

        INVALID_FEATURE_CATEGORY_MSG = "'feature_category' is invalid. " \
                                       "List of valid ones can be found in #{FEATURE_CATEGORIES_FILE_PATH}"

        RESTRICT_ON_SEND = [:feature_category].freeze

        class << self
          attr_accessor :available_feature_categories
        end

        def_node_search :feature_category?, <<~PATTERN
          (:send nil? :feature_category ...)
        PATTERN

        def on_new_investigation
          super

          # Defined only once per rubocop whole run instead of each file.
          fetch_available_feature_categories unless self.class.available_feature_categories.present?
        end

        def on_class(node)
          return unless in_background_migration?(node) && node.parent_class&.short_name == :BatchedMigrationJob

          add_offense(node) unless feature_category?(node)
        end

        def on_send(node)
          return unless in_background_migration?(node)

          add_offense(node, message: INVALID_FEATURE_CATEGORY_MSG) unless valid_feature_category?(node)
        end

        private

        def valid_feature_category?(node)
          feature_category = node.descendants.first.value
          self.class.available_feature_categories.include?(feature_category.to_s)
        end

        def fetch_available_feature_categories
          self.class.available_feature_categories = YAML.load_file(FEATURE_CATEGORIES_FILE_PATH).to_set
        end
      end
    end
  end
end
