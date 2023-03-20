# frozen_string_literal: true

module Sidebars
  module Explore
    module Menus
      class GroupsMenu < ::Sidebars::Menu
        override :link
        def link
          explore_groups_path
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
          true
        end

        override :active_routes
        def active_routes
          { controller: ['explore/groups'] }
        end
      end
    end
  end
end
