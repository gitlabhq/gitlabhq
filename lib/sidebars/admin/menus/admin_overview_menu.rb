# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class AdminOverviewMenu < ::Sidebars::Admin::BaseMenu
        override :configure_menu_items
        def configure_menu_items
          add_item(dashboard_menu_item)
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
          { 'data-qa-selector': 'admin_overview_submenu_content' }
        end

        private

        def dashboard_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Dashboard'),
            link: admin_root_path,
            active_routes: { controller: 'dashboard' },
            item_id: :dashboard
          )
        end

        def projects_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Projects'),
            link: admin_projects_path,
            active_routes: { controller: 'admin/projects' },
            item_id: :projects
          )
        end

        def users_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Users'),
            link: admin_users_path,
            active_routes: { controller: 'users' },
            item_id: :users,
            container_html_options: { 'data-qa-selector': 'admin_overview_users_link' }
          )
        end

        def groups_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Groups'),
            link: admin_groups_path,
            active_routes: { controller: 'groups' },
            item_id: :groups,
            container_html_options: { 'data-qa-selector': 'admin_overview_groups_link' }
          )
        end

        def topics_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Topics'),
            link: admin_topics_path,
            active_routes: { controller: 'admin/topics' },
            item_id: :topics
          )
        end

        def gitaly_servers_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Gitaly Servers'),
            link: admin_gitaly_servers_path,
            active_routes: { controller: 'gitaly_servers' },
            item_id: :gitaly_servers
          )
        end
      end
    end
  end
end
