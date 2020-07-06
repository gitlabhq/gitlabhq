# frozen_string_literal: true

module ControllerWithFeatureCategory
  extend ActiveSupport::Concern
  include Gitlab::ClassAttributes

  class_methods do
    def feature_category(category, config = {})
      validate_config!(config)

      category_config = Config.new(category, config[:only], config[:except], config[:if], config[:unless])
      # Add the config to the beginning. That way, the last defined one takes precedence.
      feature_category_configuration.unshift(category_config)
    end

    def feature_category_for_action(action)
      category_config = feature_category_configuration.find { |config| config.matches?(action) }

      category_config&.category || superclass_feature_category_for_action(action)
    end

    private

    def validate_config!(config)
      invalid_keys = config.keys - [:only, :except, :if, :unless]
      if invalid_keys.any?
        raise ArgumentError, "unknown arguments: #{invalid_keys} "
      end

      if config.key?(:only) && config.key?(:except)
        raise ArgumentError, "cannot configure both `only` and `except`"
      end
    end

    def feature_category_configuration
      class_attributes[:feature_category_config] ||= []
    end

    def superclass_feature_category_for_action(action)
      return unless superclass.respond_to?(:feature_category_for_action)

      superclass.feature_category_for_action(action)
    end
  end
end
