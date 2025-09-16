# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class AdminOverviewMenu < ::Sidebars::Admin::BaseMenu
        include ::Organizations::OrganizationHelper

        override :configure_menu_items
        def configure_menu_items
          add_item(dashboard_menu_item)
          add_item(organizations_menu_item)
          add_item(projects_menu_item)
          add_item(users_menu_item)
          add_item(groups_menu_item)
          add_item(topics_menu_item)
          add_item(gitaly_servers_menu_item)

          true
        end

        override :title
        def title
          s_('Admin|Overview')
        end

        override :sprite_icon
        def sprite_icon
          'overview'
        end

        override :extra_container_html_options
        def extra_container_html_options
          { testid: 'admin-overview-submenu-content' }
        end

        override :render_with_abilities
        def render_with_abilities
          super + %i[access_admin_area]
        end

        private

        def dashboard_menu_item
          build_menu_item(
            title: _('Dashboard'),
            link: admin_root_path,
            active_routes: { controller: 'dashboard' },
            item_id: :dashboard
          ) { can?(current_user, :read_application_statistics) }
        end

        def projects_menu_item
          build_menu_item(
            title: _('Projects'),
            link: admin_projects_path,
            active_routes: { controller: 'admin/projects' },
            item_id: :projects
          ) { can?(current_user, :read_admin_projects) }
        end

        def users_menu_item
          build_menu_item(
            title: _('Users'),
            link: admin_users_path,
            active_routes: { controller: 'admin/users' },
            item_id: :users,
            container_html_options: { 'data-testid': 'admin-overview-users-link' }
          ) { can?(current_user, :read_admin_users) }
        end

        def groups_menu_item
          build_menu_item(
            title: _('Groups'),
            link: admin_groups_path,
            active_routes: { controller: 'groups' },
            item_id: :groups,
            container_html_options: { 'data-testid': 'admin-overview-groups-link' }
          ) { can?(current_user, :read_admin_groups) }
        end

        def organizations_menu_item
          return unless ui_for_organizations_enabled?

          build_menu_item(
            title: _('Organizations'),
            link: admin_organizations_path,
            active_routes: { controller: 'organizations' },
            item_id: :organizations,
            container_html_options: { 'data-testid': 'admin-overview-organizations-link' }
          ) { can?(current_user, :admin_all_resources) }
        end

        def topics_menu_item
          build_menu_item(
            title: _('Topics'),
            link: admin_topics_path,
            active_routes: { controller: 'admin/topics' },
            item_id: :topics
          ) { can?(current_user, :admin_all_resources) }
        end

        def gitaly_servers_menu_item
          build_menu_item(
            title: _('Gitaly servers'),
            link: admin_gitaly_servers_path,
            active_routes: { controller: 'gitaly_servers' },
            item_id: :gitaly_servers
          ) { can?(current_user, :read_admin_gitaly_servers) }
        end
      end
    end
  end
end

Sidebars::Admin::Menus::AdminOverviewMenu.prepend_mod
