# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- This has to be named this way.
module Sidebars
  module Groups
    module Menus
      class ObservabilityMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false unless feature_enabled?

          add_item(services_menu_item)
          add_item(traces_explorer_menu_item)
          add_item(logs_explorer_menu_item)
          add_item(metrics_explorer_menu_item)
          add_item(infrastructure_monitoring_menu_item)
          add_item(dashboard_menu_item)
          add_item(messaging_queues_menu_item)
          add_item(api_monitoring_menu_item)
          add_item(alerts_menu_item)
          add_item(exceptions_menu_item)
          add_item(service_map_menu_item)
          add_item(settings_menu_item)

          true
        end

        override :title
        def title
          _('Observability')
        end

        override :sprite_icon
        def sprite_icon
          'eye'
        end

        override :link
        def link
          services_menu_item.link if services_menu_item.render?
        end

        override :active_routes
        def active_routes
          { controller: 'groups/observability' }
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-observability'
          }
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def feature_enabled?
          ::Feature.enabled?(:observability_sass_features, context.group)
        end

        def services_menu_item
          link = group_observability_path(context.group, 'services')
          ::Sidebars::MenuItem.new(
            title: _('Services'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :services,
            container_html_options: { class: 'shortcuts-services' }
          )
        end

        def traces_explorer_menu_item
          link = group_observability_path(context.group, 'traces-explorer')
          ::Sidebars::MenuItem.new(
            title: _('Traces Explorer'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :traces_explorer,
            container_html_options: { class: 'shortcuts-traces' }
          )
        end

        def logs_explorer_menu_item
          link = group_observability_path(context.group, 'logs/logs-explorer')
          ::Sidebars::MenuItem.new(
            title: _('Logs Explorer'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :logs_explorer,
            container_html_options: { class: 'shortcuts-logs' }
          )
        end

        def metrics_explorer_menu_item
          link = group_observability_path(context.group, 'metrics-explorer/summary')
          ::Sidebars::MenuItem.new(
            title: _('Metrics Explorer'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :metrics_explorer,
            container_html_options: { class: 'shortcuts-metrics' }
          )
        end

        def infrastructure_monitoring_menu_item
          link = group_observability_path(context.group, 'infrastructure-monitoring/hosts')
          ::Sidebars::MenuItem.new(
            title: _('Infrastructure Monitoring'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :infrastructure_monitoring,
            container_html_options: { class: 'shortcuts-infrastructure' }
          )
        end

        def dashboard_menu_item
          link = group_observability_path(context.group, 'dashboard')
          ::Sidebars::MenuItem.new(
            title: _('Dashboard'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :dashboard,
            container_html_options: { class: 'shortcuts-dashboard' }
          )
        end

        def messaging_queues_menu_item
          link = group_observability_path(context.group, 'messaging-queues')
          ::Sidebars::MenuItem.new(
            title: _('Messaging Queues'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :messaging_queues,
            container_html_options: { class: 'shortcuts-messaging-queues' }
          )
        end

        def api_monitoring_menu_item
          link = group_observability_path(context.group, 'api-monitoring/explorer')
          ::Sidebars::MenuItem.new(
            title: _('API Monitoring'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :api_monitoring,
            container_html_options: { class: 'shortcuts-api-monitoring' }
          )
        end

        def alerts_menu_item
          link = group_observability_path(context.group, 'alerts')
          ::Sidebars::MenuItem.new(
            title: _('Alerts'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :alerts,
            container_html_options: { class: 'shortcuts-alerts' }
          )
        end

        def exceptions_menu_item
          link = group_observability_path(context.group, 'exceptions')
          ::Sidebars::MenuItem.new(
            title: _('Exceptions'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :exceptions,
            container_html_options: { class: 'shortcuts-exceptions' }
          )
        end

        def service_map_menu_item
          link = group_observability_path(context.group, 'service-map')
          ::Sidebars::MenuItem.new(
            title: _('Service Map'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :service_map,
            container_html_options: { class: 'shortcuts-service-map' }
          )
        end

        def settings_menu_item
          link = group_observability_path(context.group, 'settings')
          ::Sidebars::MenuItem.new(
            title: _('Settings'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :settings,
            container_html_options: { class: 'shortcuts-settings' }
          )
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
