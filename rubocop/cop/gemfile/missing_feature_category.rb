# frozen_string_literal: true

require_relative '../../feature_categories'

module RuboCop
  module Cop
    module Gemfile
      # Ensures that feature categories are specified for each gems.
      #
      # @example
      #
      #   # bad
      #   gem 'foo'
      #   gem 'bar', feature_category: :invalid
      #
      #   # good
      #   gem 'foo', feature_category: :wiki
      #   gem 'bar', feature_category: :tooling
      #   gem 'baz', feature_category: :shared
      #
      class MissingFeatureCategory < RuboCop::Cop::Base
        DOCUMENT_LINK = 'https://docs.gitlab.com/ee/development/feature_categorization/#gemfile'

        def_node_matcher :send_gem, <<~PATTERN
          (send nil? :gem ...)
        PATTERN

        def_node_matcher :feature_category_value, <<~PATTERN
          (send nil? :gem
            ...
            (hash <(pair (sym :feature_category) $_) ...>)
            ...
          )
        PATTERN

        def on_send(node)
          return unless send_gem(node)

          value_node = feature_category_value(node)

          feature_categories.check(
            value_node: value_node,
            document_link: DOCUMENT_LINK
          ) do |message|
            add_offense(value_node || node, message: message)
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
