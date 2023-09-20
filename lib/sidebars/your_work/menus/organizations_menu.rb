# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class OrganizationsMenu < ::Sidebars::Menu
        override :link
        def link
          organizations_path
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
          !!context.current_user && Feature.enabled?(:ui_for_organizations, context.current_user)
        end

        override :active_routes
        def active_routes
          { controller: 'organizations/organizations', actions: %w[index new] }
        end
      end
    end
  end
end
