# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class MonitorMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :configure_menu_items
        def configure_menu_items
          return false unless feature_enabled?

          add_item(traces_explorer_menu_item)
          add_item(metrics_explorer_menu_item)
          add_item(logs_explorer_menu_item)
          add_item(error_tracking_menu_item)
          add_item(alert_management_menu_item)
          add_item(incidents_menu_item)

          true
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-monitor'
          }
        end

        override :title
        def title
          _('Monitor')
        end

        override :sprite_icon
        def sprite_icon
          'monitor'
        end

        override :active_routes
        def active_routes
          { controller: [:user, :gcp] }
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def feature_enabled?
          context.project.feature_available?(:monitor, context.current_user)
        end

        def error_tracking_menu_item
          should_hide_menu = Feature.enabled?(:hide_error_tracking_features, context.project) ||
            !can?(context.current_user, :read_sentry_issue, context.project)

          return ::Sidebars::NilMenuItem.new(item_id: :error_tracking) if should_hide_menu

          ::Sidebars::MenuItem.new(
            title: _('Error Tracking'),
            link: project_error_tracking_index_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::MonitorMenu,
            active_routes: { controller: :error_tracking },
            item_id: :error_tracking
          )
        end

        def alert_management_menu_item
          should_hide_menu = Feature.enabled?(:hide_incident_management_features, context.project) ||
            !can?(context.current_user, :read_alert_management_alert, context.project)

          return ::Sidebars::NilMenuItem.new(item_id: :incidents) if should_hide_menu

          ::Sidebars::MenuItem.new(
            title: _('Alerts'),
            link: project_alert_management_index_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::MonitorMenu,
            active_routes: { controller: :alert_management },
            item_id: :alert_management
          )
        end

        def incidents_menu_item
          should_hide_menu = Feature.enabled?(:hide_incident_management_features, context.project) ||
            !can?(context.current_user, :read_issue, context.project)

          return ::Sidebars::NilMenuItem.new(item_id: :incidents) if should_hide_menu

          ::Sidebars::MenuItem.new(
            title: _('Incidents'),
            link: project_incidents_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::MonitorMenu,
            active_routes: { controller: [:incidents, :incident_management] },
            item_id: :incidents
          )
        end

        def observability_portal_allowed?
          return false unless context.project.group

          ::Feature.enabled?(:observability_sass_features, context.project.group) &&
            Ability.allowed?(context.current_user, :read_observability_portal, context.project.group)
        end
        strong_memoize_attr :observability_portal_allowed?

        def traces_explorer_menu_item
          return ::Sidebars::NilMenuItem.new(item_id: :traces_explorer) unless observability_portal_allowed?

          link = project_observability_path(context.project, 'traces-explorer')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Traces'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::MonitorMenu,
            active_routes: { page: link },
            item_id: :traces_explorer,
            container_html_options: { class: 'shortcuts-traces js-observability-nav' }
          )
        end

        def metrics_explorer_menu_item
          return ::Sidebars::NilMenuItem.new(item_id: :metrics_explorer) unless observability_portal_allowed?

          link = project_observability_sub_path_path(context.project, 'metrics-explorer/summary')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Metrics'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::MonitorMenu,
            active_routes: { page: link },
            item_id: :metrics_explorer,
            container_html_options: { class: 'shortcuts-metrics js-observability-nav' }
          )
        end

        def logs_explorer_menu_item
          return ::Sidebars::NilMenuItem.new(item_id: :logs_explorer) unless observability_portal_allowed?

          link = project_observability_sub_path_path(context.project, 'logs/logs-explorer')
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Logs'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::MonitorMenu,
            active_routes: { page: link },
            item_id: :logs_explorer,
            container_html_options: { class: 'shortcuts-logs js-observability-nav' }
          )
        end
      end
    end
  end
end

Sidebars::Projects::Menus::MonitorMenu.prepend_mod_with('Sidebars::Projects::Menus::MonitorMenu')
