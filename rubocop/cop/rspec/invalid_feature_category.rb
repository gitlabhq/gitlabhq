# frozen_string_literal: true

require 'rubocop/cop/rspec/base'
require 'rubocop/cop/rspec/mixin/top_level_group'

require_relative '../../feature_categories'

module RuboCop
  module Cop
    module RSpec
      # Ensures that feature categories in specs are valid.
      #
      # @example
      #
      #   # bad
      #   RSpec.describe 'foo', feature_category: :invalid do
      #   end
      #
      #   RSpec.describe 'foo', feature_category: :not_owned do
      #   end
      #
      #   # good
      #
      #   RSpec.describe 'foo', feature_category: :wiki do
      #   end
      #
      #   RSpec.describe 'foo', feature_category: :tooling do
      #   end
      #
      class InvalidFeatureCategory < RuboCop::Cop::RSpec::Base
        DOCUMENT_LINK = 'https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples'

        # @!method feature_category?(node)
        def_node_matcher :feature_category_value, <<~PATTERN
          (block
            (send #rspec? {#ExampleGroups.all #Examples.all} ...
              (hash <(pair (sym :feature_category) $_) ...>)
            )
            ...
          )
        PATTERN

        def on_block(node)
          value_node = feature_category_value(node)
          return unless value_node

          feature_categories.check(
            value_node: value_node,
            document_link: DOCUMENT_LINK
          ) do |message|
            add_offense(value_node, message: message)
          end
        end

        def external_dependency_checksum
          FeatureCategories.config_checksum
        end

        private

        def feature_categories
          @feature_categories ||=
            FeatureCategories.new(FeatureCategories.available_with_custom)
        end
      end
    end
  end
end
