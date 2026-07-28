# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- This has to be named this way.
module Sidebars
  module Projects
    module Menus
      class ObserveMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :configure_menu_items
        def configure_menu_items
          return false unless observability_portal_allowed?

          if observability_setting&.persisted?
            add_item(logs_explorer_menu_item)
            add_item(traces_explorer_menu_item)
            add_item(metrics_explorer_menu_item)
            add_item(infrastructure_monitoring_menu_item)
            add_item(services_menu_item)
            add_item(dashboard_menu_item)
            add_item(observability_alerts_menu_item)
            add_item(exceptions_menu_item)
            add_item(service_map_menu_item)
            add_item(messaging_queues_menu_item)
            add_item(api_monitoring_menu_item)
            add_item(notification_channels_menu_item)
            add_item(api_keys_menu_item)
          end

          add_item(setup_menu_item)

          true
        end

        override :title
        def title
          _('Observe')
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
          { controller: 'projects/observability' }
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

        def observability_portal_allowed?
          if context.project.group
            ::Feature.enabled?(:observability_sass_features, context.project.group) &&
              Ability.allowed?(context.current_user, :read_observability_portal, context.project.group)
          else
            ::Feature.enabled?(:observability_saas_features_user_namespace, context.project.root_namespace) &&
              Ability.allowed?(context.current_user, :read_observability_portal, context.project)
          end
        end
        strong_memoize_attr :observability_portal_allowed?

        def observability_setting
          ::Observability::GroupO11ySetting.observability_setting_for(context.project)
        end
        strong_memoize_attr :observability_setting

        def logs_explorer_menu_item
          link = project_observability_path(context.project, 'logs/logs-explorer')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Logs'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :logs_explorer,
            container_html_options: { class: 'shortcuts-logs js-observability-nav' },
            description: s_('Observability|Search and analyze application logs'),
            library_icon: 'log'
          )
        end
        strong_memoize_attr :logs_explorer_menu_item

        def traces_explorer_menu_item
          link = project_observability_path(context.project, 'traces-explorer')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Traces'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :traces_explorer,
            container_html_options: { class: 'shortcuts-traces js-observability-nav' },
            description: s_('Observability|Explore and analyze distributed traces'),
            library_icon: 'traces'
          )
        end

        def metrics_explorer_menu_item
          link = project_observability_path(context.project, 'metrics-explorer/summary')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Metrics'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :metrics_explorer,
            container_html_options: { class: 'shortcuts-metrics js-observability-nav' },
            description: s_('Observability|Visualize and monitor application and infrastructure metrics'),
            library_icon: 'metrics'
          )
        end

        def infrastructure_monitoring_menu_item
          link = project_observability_path(context.project, 'infrastructure-monitoring/hosts')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Infrastructure'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :infrastructure_monitoring,
            container_html_options: { class: 'shortcuts-infrastructure js-observability-nav' },
            description: s_('Observability|Monitor infrastructure and hosts'),
            library_icon: 'infrastructure'
          )
        end

        def services_menu_item
          link = project_observability_path(context.project, 'services')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Services'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :services,
            container_html_options: { class: 'shortcuts-services js-observability-nav' },
            description: s_('Observability|List services sending observability data'),
            library_icon: 'services'
          )
        end

        def dashboard_menu_item
          link = project_observability_path(context.project, 'dashboard')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Dashboards'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :observability_dashboard,
            container_html_options: { class: 'shortcuts-dashboard js-observability-nav' },
            description: s_('Observability|Custom observability dashboards'),
            library_icon: 'dashboard'
          )
        end

        def observability_alerts_menu_item
          link = project_observability_path(context.project, 'alerts')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Alerts'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :observability_alerts,
            container_html_options: { class: 'shortcuts-alerts js-observability-nav' },
            description: s_('Observability|Manage alerts and notifications'),
            library_icon: 'warning'
          )
        end

        def exceptions_menu_item
          link = project_observability_path(context.project, 'exceptions')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Exceptions'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :exceptions,
            container_html_options: { class: 'shortcuts-exceptions js-observability-nav' },
            description: s_('Observability|Track application exceptions'),
            library_icon: 'exceptions'
          )
        end

        def service_map_menu_item
          link = project_observability_path(context.project, 'service-map')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Service map'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :service_map,
            container_html_options: { class: 'shortcuts-service-map js-observability-nav' },
            description: s_('Observability|Visualize service dependencies'),
            library_icon: 'service-map'
          )
        end

        def messaging_queues_menu_item
          link = project_observability_path(context.project, 'messaging-queues')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Messaging queues'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :messaging_queues,
            container_html_options: { class: 'shortcuts-messaging-queues js-observability-nav' },
            description: s_('Observability|Monitor message queues'),
            library_icon: 'messaging-queues'
          )
        end

        def api_monitoring_menu_item
          link = project_observability_path(context.project, 'api-monitoring/explorer')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|External APIs'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :api_monitoring,
            container_html_options: { class: 'shortcuts-api-monitoring js-observability-nav' },
            description: s_('Observability|Monitor API performance'),
            library_icon: 'api'
          )
        end

        def notification_channels_menu_item
          link = project_observability_path(context.project, 'settings/channels')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Notification channels'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :notification_channels,
            container_html_options: { class: 'shortcuts-notification-channels js-observability-nav' },
            description: s_('Observability|Configure notification channels'),
            library_icon: 'notification-channels'
          )
        end

        def api_keys_menu_item
          link = project_observability_path(context.project, 'settings/api-keys')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|API keys'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            active_routes: { page: link },
            item_id: :api_keys,
            container_html_options: { class: 'shortcuts-api-keys js-observability-nav' },
            description: s_('Observability|Manage API keys for observability access'),
            library_icon: 'key'
          )
        end

        def setup_menu_item
          link = project_observability_setup_path(context.project)
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Setup'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ObserveMenu,
            item_id: :setup,
            container_html_options: { class: 'shortcuts-request-access' },
            active_routes: { page: link },
            description: s_('Observability|Set up observability'),
            library_icon: 'setup'
          )
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts

Sidebars::Projects::Menus::ObserveMenu.prepend_mod_with('Sidebars::Projects::Menus::ObserveMenu')
