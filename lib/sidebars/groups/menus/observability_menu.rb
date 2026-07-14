# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- This has to be named this way.
module Sidebars
  module Groups
    module Menus
      class ObservabilityMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false unless o11y_settings_access_enabled? || (feature_enabled? && observability_access?)

          if context.group.observability_group_o11y_setting&.persisted?
            add_item(logs_explorer_menu_item)
            add_item(traces_explorer_menu_item)
            add_item(metrics_explorer_menu_item)
            add_item(infrastructure_monitoring_menu_item)
            add_item(services_menu_item)
            add_item(dashboard_menu_item)
            add_item(alerts_menu_item)
            add_item(exceptions_menu_item)
            add_item(service_map_menu_item)
            add_item(messaging_queues_menu_item)
            add_item(api_monitoring_menu_item)
            add_item(notification_channels_menu_item)
            add_item(api_keys_menu_item)
          end

          add_item(setup_menu_item)

          add_item(o11y_settings_menu_item) if o11y_settings_access_enabled?

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
          logs_explorer_menu_item.link if logs_explorer_menu_item.render?
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

        def observability_access?
          Ability.allowed?(context.current_user, :read_observability_portal, context.group)
        end

        def feature_enabled?
          ::Feature.enabled?(:observability_sass_features, context.group)
        end

        def o11y_settings_access_enabled?
          ::Feature.enabled?(:o11y_settings_access, context.current_user)
        end

        def services_menu_item
          link = group_observability_path(context.group, 'services')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Services'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :services,
            description: s_('Observability|Monitor service health and performance'),
            library_icon: 'services',
            container_html_options: { class: 'shortcuts-services js-observability-nav' }
          )
        end

        def traces_explorer_menu_item
          link = group_observability_path(context.group, 'traces-explorer')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Traces'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :traces_explorer,
            description: s_('Observability|Explore and analyze distributed traces'),
            library_icon: 'traces',
            container_html_options: { class: 'shortcuts-traces js-observability-nav' }
          )
        end

        def logs_explorer_menu_item
          link = group_observability_path(context.group, 'logs/logs-explorer')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Logs'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :logs_explorer,
            description: s_('Observability|Search and analyze application logs'),
            library_icon: 'log',
            container_html_options: { class: 'shortcuts-logs js-observability-nav' }
          )
        end

        def metrics_explorer_menu_item
          link = group_observability_path(context.group, 'metrics-explorer/summary')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Metrics'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :metrics_explorer,
            description: s_('Observability|Visualize and monitor application and infrastructure metrics'),
            library_icon: 'metrics',
            container_html_options: { class: 'shortcuts-metrics js-observability-nav' }
          )
        end

        def infrastructure_monitoring_menu_item
          link = group_observability_path(context.group, 'infrastructure-monitoring/hosts')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Infrastructure'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :infrastructure_monitoring,
            description: s_('Observability|Monitor infrastructure and hosts'),
            library_icon: 'infrastructure',
            container_html_options: { class: 'shortcuts-infrastructure js-observability-nav' }
          )
        end

        def dashboard_menu_item
          link = group_observability_path(context.group, 'dashboard')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Dashboards'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :dashboard,
            description: s_('Observability|View observability overview'),
            library_icon: 'dashboard',
            container_html_options: { class: 'shortcuts-dashboard js-observability-nav' }
          )
        end

        def messaging_queues_menu_item
          link = group_observability_path(context.group, 'messaging-queues')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Messaging queues'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :messaging_queues,
            description: s_('Observability|Monitor message queues'),
            library_icon: 'messaging-queues',
            container_html_options: { class: 'shortcuts-messaging-queues js-observability-nav' }
          )
        end

        def api_monitoring_menu_item
          link = group_observability_path(context.group, 'api-monitoring/explorer')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|External APIs'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :api_monitoring,
            description: s_('Observability|Monitor API performance'),
            library_icon: 'api',
            container_html_options: { class: 'shortcuts-api-monitoring js-observability-nav' }
          )
        end

        def alerts_menu_item
          link = group_observability_path(context.group, 'alerts')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Alerts'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :alerts,
            description: s_('Observability|Manage alerts and notifications'),
            library_icon: 'warning',
            container_html_options: { class: 'shortcuts-alerts js-observability-nav' }
          )
        end

        def exceptions_menu_item
          link = group_observability_path(context.group, 'exceptions')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Exceptions'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :exceptions,
            description: s_('Observability|Track application exceptions'),
            library_icon: 'exception',
            container_html_options: { class: 'shortcuts-exceptions js-observability-nav' }
          )
        end

        def service_map_menu_item
          link = group_observability_path(context.group, 'service-map')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Service map'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :service_map,
            description: s_('Observability|Visualize service dependencies'),
            library_icon: 'service-map',
            container_html_options: { class: 'shortcuts-service-map js-observability-nav' }
          )
        end

        def notification_channels_menu_item
          link = group_observability_path(context.group, 'settings/channels')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Notification channels'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :notification_channels,
            description: s_('Observability|Configure notification channels'),
            library_icon: 'notification-channels',
            container_html_options: { class: 'shortcuts-notification-channels js-observability-nav' }
          )
        end

        def api_keys_menu_item
          link = group_observability_path(context.group, 'settings/api-keys')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|API keys'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :api_keys,
            description: s_('Observability|Manage API keys for observability ingestion'),
            library_icon: 'key',
            container_html_options: { class: 'shortcuts-api-keys js-observability-nav' }
          )
        end

        def o11y_settings_menu_item
          link = edit_group_observability_o11y_service_settings_path(context.group)
          ::Sidebars::MenuItem.new(
            title: s_('Observability|O11y service settings'),
            link: link,
            active_routes: { page: link },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :o11y_settings,
            description: s_('Observability|Configure observability settings'),
            library_icon: 'observability-settings',
            container_html_options: { class: 'shortcuts-o11y-settings' }
          )
        end

        def setup_menu_item
          link = group_observability_setup_path(context.group)
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Setup'),
            link: link,
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu,
            item_id: :setup,
            description: s_('Observability|Set up observability'),
            library_icon: 'setup',
            container_html_options: { class: 'shortcuts-request-access' },
            active_routes: { page: link }
          )
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
