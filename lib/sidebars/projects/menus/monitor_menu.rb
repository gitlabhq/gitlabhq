# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class MonitorMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false unless context.project.feature_available?(:operations, context.current_user)

          add_item(metrics_dashboard_menu_item)
          add_item(logs_menu_item)
          add_item(tracing_menu_item)
          add_item(error_tracking_menu_item)
          add_item(alert_management_menu_item)
          add_item(incidents_menu_item)
          add_item(serverless_menu_item)
          add_item(terraform_menu_item)
          add_item(kubernetes_menu_item)
          add_item(environments_menu_item)
          add_item(feature_flags_menu_item)
          add_item(product_analytics_menu_item)

          true
        end

        override :link
        def link
          if can?(context.current_user, :read_environment, context.project)
            metrics_project_environments_path(context.project)
          else
            project_feature_flags_path(context.project)
          end
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: Feature.enabled?(:sidebar_refactor, context.current_user, default_enabled: :yaml) ? 'shortcuts-monitor' : 'shortcuts-operations'
          }
        end

        override :title
        def title
          Feature.enabled?(:sidebar_refactor, context.current_user, default_enabled: :yaml) ? _('Monitor') : _('Operations')
        end

        override :sprite_icon
        def sprite_icon
          Feature.enabled?(:sidebar_refactor, context.current_user, default_enabled: :yaml) ? 'monitor' : 'cloud-gear'
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

        def logs_menu_item
          if !can?(context.current_user, :read_environment, context.project) ||
            !can?(context.current_user, :read_pod_logs, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :logs)
          end

          ::Sidebars::MenuItem.new(
            title: _('Logs'),
            link: project_logs_path(context.project),
            active_routes: { path: 'logs#index' },
            item_id: :logs
          )
        end

        def tracing_menu_item
          if !can?(context.current_user, :read_environment, context.project) ||
            !can?(context.current_user, :admin_project, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :tracing)
          end

          ::Sidebars::MenuItem.new(
            title: _('Tracing'),
            link: project_tracing_path(context.project),
            active_routes: { path: 'tracings#show' },
            item_id: :tracing
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

        def serverless_menu_item
          if Feature.enabled?(:sidebar_refactor, context.current_user) ||
            !can?(context.current_user, :read_cluster, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :serverless)
          end

          ::Sidebars::MenuItem.new(
            title: _('Serverless'),
            link: project_serverless_functions_path(context.project),
            active_routes: { controller: :functions },
            item_id: :serverless
          )
        end

        def terraform_menu_item
          if Feature.enabled?(:sidebar_refactor, context.current_user) ||
            !can?(context.current_user, :read_terraform_state, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :terraform)
          end

          ::Sidebars::MenuItem.new(
            title: _('Terraform'),
            link: project_terraform_index_path(context.project),
            active_routes: { controller: :terraform },
            item_id: :terraform
          )
        end

        def kubernetes_menu_item
          if Feature.enabled?(:sidebar_refactor, context.current_user) ||
            !can?(context.current_user, :read_cluster, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :kubernetes)
          end

          ::Sidebars::MenuItem.new(
            title: _('Kubernetes'),
            link: project_clusters_path(context.project),
            active_routes: { controller: [:cluster_agents, :clusters] },
            container_html_options: { class: 'shortcuts-kubernetes' },
            hint_html_options: kubernetes_hint_html_options,
            item_id: :kubernetes
          )
        end

        def kubernetes_hint_html_options
          return {} unless context.show_cluster_hint

          { disabled: true,
            data: { trigger: 'manual',
              container: 'body',
              placement: 'right',
              highlight: UserCalloutsHelper::GKE_CLUSTER_INTEGRATION,
              highlight_priority: UserCallout.feature_names[:GKE_CLUSTER_INTEGRATION],
              dismiss_endpoint: user_callouts_path,
              auto_devops_help_path: help_page_path('topics/autodevops/index.md') } }
        end

        def environments_menu_item
          if Feature.enabled?(:sidebar_refactor, context.current_user, default_enabled: :yaml) ||
            !can?(context.current_user, :read_environment, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :environments)
          end

          ::Sidebars::MenuItem.new(
            title: _('Environments'),
            link: project_environments_path(context.project),
            active_routes: { controller: :environments },
            container_html_options: { class: 'shortcuts-environments' },
            item_id: :environments
          )
        end

        def feature_flags_menu_item
          if Feature.enabled?(:sidebar_refactor, context.current_user, default_enabled: :yaml) ||
            !can?(context.current_user, :read_feature_flag, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :feature_flags)
          end

          ::Sidebars::MenuItem.new(
            title: _('Feature Flags'),
            link: project_feature_flags_path(context.project),
            active_routes: { controller: :feature_flags },
            container_html_options: { class: 'shortcuts-feature-flags' },
            item_id: :feature_flags
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
