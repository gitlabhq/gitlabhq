# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module FeatureValidation
        def validate_supported_features!(work_item_type, resource_parent, widget_params)
          unsupported = widget_params.keys - work_item_type.widget_classes(resource_parent).map(&:api_symbol)
          return if unsupported.blank?

          unsupported_features = unsupported.map { |key| key.to_s.delete_suffix('_widget') }
          message = "Following features are not supported by #{work_item_type.name} type: " \
            "#{unsupported_features.join(', ')}"

          render_structured_api_error!({ error: message, unsupported_features: unsupported_features }, :bad_request)
        end

        def strip_disabled_feature_params!(widget_params, work_item_type, resource_parent)
          type_supported_keys = work_item_type.widget_definitions.filter_map(&:widget_class).map(&:api_symbol)
          enabled_keys = work_item_type.widget_classes(resource_parent).map(&:api_symbol)
          disabled_keys = type_supported_keys - enabled_keys

          disabled_keys.each { |key| widget_params.delete(key) }
        end
      end
    end
  end
end
