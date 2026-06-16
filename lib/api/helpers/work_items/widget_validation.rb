# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module WidgetValidation
        def validate_supported_widgets!(work_item_type, resource_parent, widget_params)
          unsupported = widget_params.keys - work_item_type.widget_classes(resource_parent).map(&:api_symbol)
          return if unsupported.blank?

          message = "Following widget keys are not supported by #{work_item_type.name} type: #{unsupported.join(', ')}"

          render_structured_api_error!({ error: message, unsupported_widgets: unsupported }, :bad_request)
        end

        def strip_disabled_widget_params!(widget_params, work_item_type, resource_parent)
          type_supported_keys = work_item_type.widget_definitions.filter_map(&:widget_class).map(&:api_symbol)
          enabled_keys = work_item_type.widget_classes(resource_parent).map(&:api_symbol)
          disabled_keys = type_supported_keys - enabled_keys

          disabled_keys.each { |key| widget_params.delete(key) }
        end
      end
    end
  end
end
