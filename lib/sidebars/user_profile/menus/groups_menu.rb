# frozen_string_literal: true

module Sidebars
  module UserProfile
    module Menus
      class GroupsMenu < ::Sidebars::UserProfile::BaseMenu
        override :link
        def link
          user_groups_path(context.container)
        end

        override :title
        def title
          s_('UserProfile|Groups')
        end

        override :sprite_icon
        def sprite_icon
          'group'
        end

        override :active_routes
        def active_routes
          { path: 'users#groups' }
        end
      end
    end
  end
end
