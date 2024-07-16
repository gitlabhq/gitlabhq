# frozen_string_literal: true

module Mutations
  module WorkItems
    module Widgetable
      extend ActiveSupport::Concern

      def extract_widget_params!(work_item_type, attributes, resource_parent)
        # Get the list of widgets for the work item's type to extract only the supported attributes
        widget_keys = ::WorkItems::WidgetDefinition.available_widgets.map(&:api_symbol)
        widget_params = attributes.extract!(*widget_keys)

        not_supported_keys = widget_params.keys - work_item_type.widget_classes(resource_parent).map(&:api_symbol)
        if not_supported_keys.present?
          raise Gitlab::Graphql::Errors::ArgumentError,
            "Following widget keys are not supported by #{work_item_type.name} type: #{not_supported_keys}"
        end

        # Cannot use prepare to use `.to_h` on each input due to
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87472#note_945199865
        widget_params.transform_values(&:to_h)
      end
    end
  end
end
