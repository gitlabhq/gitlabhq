# frozen_string_literal: true

module Gitlab
  module EndpointAttributes
    extend ActiveSupport::Concern
    include Gitlab::ClassAttributes

    DEFAULT_TARGET_DURATION = Config::TARGET_DURATIONS.fetch(:medium)

    class_methods do
      def feature_category(category, actions = [])
        endpoint_attributes.set(actions, feature_category: category)
      end

      def feature_category_for_action(action)
        category = endpoint_attributes.attribute_for_action(action, :feature_category)
        category || superclass_feature_category_for_action(action)
      end

      def target_duration(duration, actions = [])
        endpoint_attributes.set(actions, target_duration: duration)
      end

      def target_duration_for_action(action)
        duration = endpoint_attributes.attribute_for_action(action, :target_duration)
        duration || superclass_target_duration_for_action(action) || DEFAULT_TARGET_DURATION
      end

      private

      def endpoint_attributes
        class_attributes[:endpoint_attributes_config] ||= Config.new
      end

      def superclass_feature_category_for_action(action)
        return unless superclass.respond_to?(:feature_category_for_action)

        superclass.feature_category_for_action(action)
      end

      def superclass_target_duration_for_action(action)
        return unless superclass.respond_to?(:target_duration_for_action)

        superclass.target_duration_for_action(action)
      end
    end
  end
end
