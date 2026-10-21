# frozen_string_literal: true

module Sidebars # rubocop:disable Gitlab/BoundedContexts -- overridden class is not inside a bounded context namespace
  module Admin
    module Organizations
      module Menus
        class ScopeMenu < ::Sidebars::Admin::BaseMenu
          override :link
          def link
            # rubocop:disable Gitlab/AvoidOrganizationUrlRoutes -- We only want to generate org-scoped path here
            organization_admin_root_path(context.current_organization)
            # rubocop:enable Gitlab/AvoidOrganizationUrlRoutes
          end

          override :title
          def title
            context.current_organization.name
          end

          override :active_routes
          def active_routes
            { controller: 'admin/organizations/dashboard' }
          end

          override :serialize_as_menu_item_args
          def serialize_as_menu_item_args
            super.merge({
              avatar: context.current_organization.avatar_url(size: 48),
              entity_id: context.current_organization.id,
              super_sidebar_parent: ::Sidebars::StaticMenu,
              item_id: :organization_admin_scope
            })
          end

          private

          override :authorization_subject
          def authorization_subject
            context.current_organization
          end

          override :render_with_abilities
          def render_with_abilities
            %i[access_organization_admin_area]
          end
        end
      end
    end
  end
end
