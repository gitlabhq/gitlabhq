# frozen_string_literal: true

module Sidebars
  module Concerns
    module ShowWorkItemsBadge
      WORK_ITEMS_BADGE_EXPIRES_ON = Date.new(2026, 4, 16)

      def show_work_items_badge?
        return false unless context.current_user
        return false unless context.container.work_items_saved_views_enabled?(context.current_user)
        return false if Date.current > WORK_ITEMS_BADGE_EXPIRES_ON

        !context.current_user.dismissed_callout?(feature_name: 'work_items_nav_badge')
      end
    end
  end
end
