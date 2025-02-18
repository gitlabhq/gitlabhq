# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class AdminSettingsMenu < ::Sidebars::Admin::BaseMenu
        override :configure_menu_items
        def configure_menu_items
          add_item(general_settings_menu_item)
          add_item(search_menu_item)
          add_item(integrations_menu_item)
          add_item(repository_menu_item)
          add_item(ci_cd_menu_item)
          add_item(reporting_menu_item)
          add_item(metrics_and_profiling_menu_item)
          add_item(network_settings_menu_item)
          add_item(appearance_menu_item)
          add_item(preferences_menu_item)

          true
        end

        override :title
        def title
          s_('Admin|Settings')
        end

        override :sprite_icon
        def sprite_icon
          'settings'
        end

        override :extra_container_html_options
        def extra_container_html_options
          { testid: 'admin-settings-menu-link' }
        end

        override :separated?
        def separated?
          true
        end

        private

        def general_settings_menu_item
          ::Sidebars::MenuItem.new(
            title: _('General'),
            link: general_admin_application_settings_path,
            active_routes: { path: 'admin/application_settings#general' },
            item_id: :general_settings,
            container_html_options: { 'data-testid': 'admin-settings-general-link' }
          )
        end

        def search_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Search'),
            link: search_admin_application_settings_path,
            active_routes: { path: 'admin/application_settings#search' },
            item_id: :search,
            container_html_options: { testid: 'admin-settings-search-link' }
          )
        end

        def integrations_menu_item
          return ::Sidebars::NilMenuItem.new(item_id: :admin_integrations) unless instance_level_integrations?

          ::Sidebars::MenuItem.new(
            title: _('Integrations'),
            link: integrations_admin_application_settings_path,
            active_routes: { path: %w[application_settings#integrations integrations#edit] },
            item_id: :admin_integrations,
            container_html_options: { 'data-testid': 'admin-settings-integrations-link' }
          )
        end

        def repository_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Repository'),
            link: repository_admin_application_settings_path,
            active_routes: { path: 'admin/application_settings#repository' },
            item_id: :admin_repository,
            container_html_options: { 'data-testid': 'admin-settings-repository-link' }
          )
        end

        def ci_cd_menu_item
          ::Sidebars::MenuItem.new(
            title: _('CI/CD'),
            link: ci_cd_admin_application_settings_path,
            active_routes: { path: 'admin/application_settings#ci_cd' },
            item_id: :admin_ci_cd
          )
        end

        def reporting_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Reporting'),
            link: reporting_admin_application_settings_path,
            active_routes: { path: 'admin/application_settings#reporting' },
            item_id: :admin_reporting
          )
        end

        def metrics_and_profiling_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Metrics and profiling'),
            link: metrics_and_profiling_admin_application_settings_path,
            active_routes: { path: 'admin/application_settings#metrics_and_profiling' },
            item_id: :admin_metrics,
            container_html_options: { 'data-testid': 'admin-settings-metrics-and-profiling-link' }
          )
        end

        def network_settings_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Network'),
            link: network_admin_application_settings_path,
            active_routes: { path: 'admin/application_settings#network' },
            item_id: :admin_network,
            container_html_options: { 'data-testid': 'admin-settings-network-link' }
          )
        end

        def appearance_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Appearance'),
            link: admin_application_settings_appearances_path,
            active_routes: { path: 'admin/application_settings/appearances#show' },
            item_id: :admin_appearance
          )
        end

        def preferences_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Preferences'),
            link: preferences_admin_application_settings_path,
            active_routes: { path: 'admin/application_settings#preferences' },
            item_id: :admin_preferences,
            container_html_options: { 'data-testid': 'admin-settings-preferences-link' }
          )
        end

        def instance_level_integrations?
          !Gitlab.com?
        end
      end
    end
  end
end

Sidebars::Admin::Menus::AdminSettingsMenu.prepend_mod_with('Sidebars::Admin::Menus::AdminSettingsMenu')
