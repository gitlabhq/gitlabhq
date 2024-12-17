# frozen_string_literal: true

require 'rubocop/cop/rspec/base'
require 'rubocop/cop/rspec/mixin/top_level_group'

require_relative '../../feature_categories'

module RuboCop
  module Cop
    module RSpec
      # Ensures that feature categories in specs are present and valid.
      #
      # @example
      #
      #   # bad
      #   RSpec.describe 'foo' do
      #   end
      #
      #   RSpec.describe 'foo', feature_category: :invalid do
      #     context 'a context', feature_category: :aip do
      #     end
      #   end
      #
      #   RSpec.describe 'foo', feature_category: :not_owned do
      #   end
      #
      #   # good
      #
      #   RSpec.describe 'foo', feature_category: :wiki do
      #     context 'a context', feature_category: :api do
      #     end
      #   end
      #
      #   RSpec.describe 'foo', feature_category: :tooling do
      #   end
      #
      class FeatureCategory < RuboCop::Cop::RSpec::Base
        include RuboCop::Cop::RSpec::TopLevelGroup

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

        def on_top_level_example_group(node)
          check_feature_category(node, optional: false)
        end

        def on_block(node)
          check_feature_category(node, optional: true)
        end

        def external_dependency_checksum
          FeatureCategories.config_checksum
        end

        private

        def check_feature_category(node, optional:)
          value_node = feature_category_value(node)
          return if optional && !value_node

          feature_categories.check(
            value_node: value_node,
            document_link: DOCUMENT_LINK
          ) do |message|
            add_offense(value_node || node.send_node, message: message)
          end
        end

        def feature_categories
          @feature_categories ||=
            FeatureCategories.new(FeatureCategories.available_with_custom)
        end
      end
    end
  end
end
