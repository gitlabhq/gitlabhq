# frozen_string_literal: true

module Gitlab
  module EndpointAttributes
    extend ActiveSupport::Concern
    include Gitlab::ClassAttributes

    DEFAULT_URGENCY = Config::REQUEST_URGENCIES.fetch(:default)

    class_methods do
      def feature_category(category, actions = [])
        endpoint_attributes.set(actions, feature_category: category)
      end

      def feature_category_for_action(action)
        category = endpoint_attributes.attribute_for_action(action, :feature_category)
        category || superclass_feature_category_for_action(action)
      end

      def urgency(urgency_name, actions = [])
        endpoint_attributes.set(actions, urgency: urgency_name)
      end

      def urgency_for_action(action)
        urgency = endpoint_attributes.attribute_for_action(action, :urgency)
        urgency || superclass_urgency_for_action(action) || DEFAULT_URGENCY
      end

      private

      def endpoint_attributes
        class_attributes[:endpoint_attributes_config] ||= Config.new
      end

      def superclass_feature_category_for_action(action)
        return unless superclass.respond_to?(:feature_category_for_action)

        superclass.feature_category_for_action(action)
      end

      def superclass_urgency_for_action(action)
        return unless superclass.respond_to?(:urgency_for_action)

        superclass.urgency_for_action(action)
      end
    end
  end
end
