# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class InfrastructureMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false unless feature_enabled?

          add_item(kubernetes_menu_item)
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

        def feature_enabled?
          context.project.feature_available?(:infrastructure, context.current_user)
        end

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
          enabled_for_user = Feature.enabled?(:incubation_5mp_google_cloud, context.current_user)
          enabled_for_group = Feature.enabled?(:incubation_5mp_google_cloud, context.project.group)
          enabled_for_project = Feature.enabled?(:incubation_5mp_google_cloud, context.project)
          feature_is_enabled = enabled_for_user || enabled_for_group || enabled_for_project
          user_has_permissions = can?(context.current_user, :admin_project_google_cloud, context.project)

          unless feature_is_enabled && user_has_permissions
            return ::Sidebars::NilMenuItem.new(item_id: :incubation_5mp_google_cloud)
          end

          ::Sidebars::MenuItem.new(
            title: _('Google Cloud'),
            link: project_google_cloud_configuration_path(context.project),
            active_routes: { controller: %w[
              projects/google_cloud/configuration
              projects/google_cloud/service_accounts
              projects/google_cloud/databases
              projects/google_cloud/deployments
              projects/google_cloud/gcp_regions
            ] },
            item_id: :google_cloud
          )
        end
      end
    end
  end
end
