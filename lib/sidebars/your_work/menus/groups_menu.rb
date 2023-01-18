# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class GroupsMenu < ::Sidebars::Menu
        override :link
        def link
          dashboard_groups_path
        end

        override :title
        def title
          _('Groups')
        end

        override :sprite_icon
        def sprite_icon
          'group'
        end

        override :render?
        def render?
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { controller: ['groups', 'dashboard/groups'] }
        end
      end
    end
  end
end
