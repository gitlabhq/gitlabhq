# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetVisibility
      def widget_visible?(widget, work_item)
        ability = widget.class.required_user_ability

        return true unless ability

        Ability.allowed?(current_user, ability, work_item)
      end
    end
  end
end
