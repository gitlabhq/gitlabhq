# frozen_string_literal: true

module Sidebars
  module Explore
    module Menus
      class AnalyticsDashboardsMenu < ::Sidebars::Menu
        override :link
        def link
          explore_analytics_dashboards_path
        end

        override :title
        def title
          _('Analytics dashboards')
        end

        override :sprite_icon
        def sprite_icon
          'chart'
        end

        override :render?
        def render?
          Feature.enabled?(:explore_analytics_dashboards, current_user)
        end

        override :active_routes
        def active_routes
          { controller: ['explore/analytics_dashboards'] }
        end
      end
    end
  end
end
