# frozen_string_literal: true

module Gitlab
  module WithFeatureCategory
    extend ActiveSupport::Concern
    include Gitlab::ClassAttributes

    class_methods do
      def feature_category(category, actions = [])
        feature_category_configuration[category] ||= []
        feature_category_configuration[category] += actions.map(&:to_s)

        validate_config!(feature_category_configuration)
      end

      def feature_category_for_action(action)
        category_config = feature_category_configuration.find do |_, actions|
          actions.empty? || actions.include?(action)
        end

        category_config&.first || superclass_feature_category_for_action(action)
      end

      private

      def validate_config!(config)
        empty = config.find { |_, actions| actions.empty? }
        duplicate_actions = config.values.map(&:uniq).flatten.group_by(&:itself).select { |_, v| v.count > 1 }.keys

        if config.length > 1 && empty
          raise ArgumentError, "#{empty.first} is defined for all actions, but other categories are set"
        end

        if duplicate_actions.any?
          raise ArgumentError, "Actions have multiple feature categories: #{duplicate_actions.join(', ')}"
        end
      end

      def feature_category_configuration
        class_attributes[:feature_category_config] ||= {}
      end

      def superclass_feature_category_for_action(action)
        return unless superclass.respond_to?(:feature_category_for_action)

        superclass.feature_category_for_action(action)
      end
    end
  end
end
