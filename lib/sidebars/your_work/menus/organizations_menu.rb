# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class OrganizationsMenu < ::Sidebars::Menu
        override :link
        def link
          organizations_path(organization_path: nil)
        end

        override :title
        def title
          _('Organizations')
        end

        override :sprite_icon
        def sprite_icon
          'organization'
        end

        override :render?
        def render?
          return false unless context.current_user

          ::Organizations::Release.enrolled?(context.current_user, flag: :your_work_sidebar_org_menu_item)
        end

        override :active_routes
        def active_routes
          { controller: 'organizations/organizations', actions: %w[index new] }
        end
      end
    end
  end
end
