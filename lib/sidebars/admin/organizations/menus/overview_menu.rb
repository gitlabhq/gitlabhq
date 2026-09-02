# frozen_string_literal: true

module Sidebars
  module Admin
    module Organizations
      module Menus
        class OverviewMenu < ::Sidebars::Admin::BaseMenu
          override :configure_menu_items
          def configure_menu_items
            add_item(dashboard_menu_item)
            add_item(users_menu_item)

            true
          end

          override :title
          def title
            s_('Organization|Organization overview')
          end

          override :sprite_icon
          def sprite_icon
            'organization'
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

          def dashboard_menu_item
            build_menu_item(
              title: _('Dashboard'),
              # rubocop:disable Gitlab/AvoidOrganizationUrlRoutes -- We only want to generate org-scoped path here
              link: organization_admin_root_path(context.current_organization),
              # rubocop:enable Gitlab/AvoidOrganizationUrlRoutes
              active_routes: { controller: 'admin/organizations/dashboard' },
              item_id: :organization_admin_dashboard
            )
          end

          def users_menu_item
            build_menu_item(
              title: _('Users'),
              # rubocop:disable Gitlab/AvoidOrganizationUrlRoutes -- We only want to generate org-scoped path here
              link: organization_admin_users_path(context.current_organization),
              # rubocop:enable Gitlab/AvoidOrganizationUrlRoutes
              active_routes: { controller: 'admin/organizations/users' },
              item_id: :organization_admin_users
            )
          end
        end
      end
    end
  end
end
