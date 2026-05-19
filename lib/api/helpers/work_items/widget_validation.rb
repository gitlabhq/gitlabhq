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
      end
    end
  end
end
