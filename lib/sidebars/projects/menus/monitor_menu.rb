# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class MonitorMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false unless context.project.feature_available?(:operations, context.current_user)

          add_item(metrics_dashboard_menu_item)
          add_item(error_tracking_menu_item)
          add_item(alert_management_menu_item)
          add_item(incidents_menu_item)
          add_item(product_analytics_menu_item)

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

        private

        def metrics_dashboard_menu_item
          unless can?(context.current_user, :metrics_dashboard, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :metrics)
          end

          ::Sidebars::MenuItem.new(
            title: _('Metrics'),
            link: project_metrics_dashboard_path(context.project),
            active_routes: { path: 'metrics_dashboard#show' },
            container_html_options: { class: 'shortcuts-metrics' },
            item_id: :metrics
          )
        end

        def error_tracking_menu_item
          unless can?(context.current_user, :read_sentry_issue, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :error_tracking)
          end

          ::Sidebars::MenuItem.new(
            title: _('Error Tracking'),
            link: project_error_tracking_index_path(context.project),
            active_routes: { controller: :error_tracking },
            item_id: :error_tracking
          )
        end

        def alert_management_menu_item
          unless can?(context.current_user, :read_alert_management_alert, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :alert_management)
          end

          ::Sidebars::MenuItem.new(
            title: _('Alerts'),
            link: project_alert_management_index_path(context.project),
            active_routes: { controller: :alert_management },
            item_id: :alert_management
          )
        end

        def incidents_menu_item
          unless can?(context.current_user, :read_issue, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :incidents)
          end

          ::Sidebars::MenuItem.new(
            title: _('Incidents'),
            link: project_incidents_path(context.project),
            active_routes: { controller: [:incidents, :incident_management] },
            item_id: :incidents
          )
        end

        def product_analytics_menu_item
          if Feature.disabled?(:product_analytics, context.project) ||
            !can?(context.current_user, :read_product_analytics, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :product_analytics)
          end

          ::Sidebars::MenuItem.new(
            title: _('Product Analytics'),
            link: project_product_analytics_path(context.project),
            active_routes: { controller: :product_analytics },
            item_id: :product_analytics
          )
        end
      end
    end
  end
end

Sidebars::Projects::Menus::MonitorMenu.prepend_mod_with('Sidebars::Projects::Menus::MonitorMenu')
