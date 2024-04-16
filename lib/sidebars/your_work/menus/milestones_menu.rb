# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class MilestonesMenu < ::Sidebars::Menu
        override :link
        def link
          dashboard_milestones_path
        end

        override :title
        def title
          _('Milestones')
        end

        override :sprite_icon
        def sprite_icon
          'milestone'
        end

        override :render?
        def render?
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { controller: 'dashboard/milestones' }
        end
      end
    end
  end
end
