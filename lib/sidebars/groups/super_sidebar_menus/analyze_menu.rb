# frozen_string_literal: true

module Sidebars
  module Groups
    module SuperSidebarMenus
      class AnalyzeMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Analyze')
        end

        override :sprite_icon
        def sprite_icon
          'chart'
        end

        override :configure_menu_items
        def configure_menu_items
          [
            :analytics_dashboards,
            :cycle_analytics,
            :ci_cd_analytics,
            :contribution_analytics,
            :devops_adoption,
            :insights,
            :issues_analytics,
            :productivity_analytics,
            :repository_analytics
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
