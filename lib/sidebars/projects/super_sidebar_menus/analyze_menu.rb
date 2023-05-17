# frozen_string_literal: true

module Sidebars
  module Projects
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
            :dashboards_analytics,
            :cycle_analytics,
            :contributors,
            :ci_cd_analytics,
            :repository_analytics,
            :code_review,
            :merge_request_analytics,
            :issues,
            :insights,
            :model_experiments
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
