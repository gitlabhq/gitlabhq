# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class InfrastructureMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false unless context.project.feature_available?(:operations, context.current_user)

          add_item(kubernetes_menu_item)
          add_item(serverless_menu_item)
          add_item(terraform_menu_item)
          add_item(google_cloud_menu_item)

          true
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-infrastructure'
          }
        end

        override :title
        def title
          _('Infrastructure')
        end

        override :sprite_icon
        def sprite_icon
          'cloud-gear'
        end

        private

        def kubernetes_menu_item
          unless can?(context.current_user, :read_cluster, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :kubernetes)
          end

          ::Sidebars::MenuItem.new(
            title: _('Kubernetes clusters'),
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
              highlight: Users::CalloutsHelper::GKE_CLUSTER_INTEGRATION,
              highlight_priority: Users::Callout.feature_names[:GKE_CLUSTER_INTEGRATION],
              dismiss_endpoint: callouts_path,
              auto_devops_help_path: help_page_path('topics/autodevops/index.md') } }
        end

        def serverless_menu_item
          unless Feature.enabled?(:deprecated_serverless, context.project, default_enabled: :yaml, type: :ops) && can?(context.current_user, :read_cluster, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :serverless)
          end

          ::Sidebars::MenuItem.new(
            title: _('Serverless platform'),
            link: project_serverless_functions_path(context.project),
            active_routes: { controller: :functions },
            item_id: :serverless
          )
        end

        def terraform_menu_item
          unless can?(context.current_user, :read_terraform_state, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :terraform)
          end

          ::Sidebars::MenuItem.new(
            title: _('Terraform'),
            link: project_terraform_index_path(context.project),
            active_routes: { controller: :terraform },
            item_id: :terraform
          )
        end

        def google_cloud_menu_item
          feature_is_enabled = Feature.enabled?(:incubation_5mp_google_cloud, context.project)
          user_has_permissions = can?(context.current_user, :admin_project_google_cloud, context.project)

          unless feature_is_enabled && user_has_permissions
            return ::Sidebars::NilMenuItem.new(item_id: :incubation_5mp_google_cloud)
          end

          ::Sidebars::MenuItem.new(
            title: _('Google Cloud'),
            link: project_google_cloud_index_path(context.project),
            active_routes: { controller: [:google_cloud, :service_accounts, :deployments, :gcp_regions] },
            item_id: :google_cloud
          )
        end
      end
    end
  end
end
