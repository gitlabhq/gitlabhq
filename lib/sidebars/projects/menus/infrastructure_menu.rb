# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class InfrastructureMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false unless feature_enabled?

          add_item(kubernetes_menu_item)
          add_item(terraform_states_menu_item)
          add_item(google_cloud_menu_item)
          add_item(aws_menu_item)

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

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def feature_enabled?
          context.project.feature_available?(:infrastructure, context.current_user)
        end

        def kubernetes_menu_item
          unless can?(context.current_user, :read_cluster_agent, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :kubernetes)
          end

          ::Sidebars::MenuItem.new(
            title: _('Kubernetes clusters'),
            link: project_clusters_path(context.project),
            super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::OperationsMenu,
            active_routes: { controller: [:cluster_agents, :clusters] },
            container_html_options: { class: 'shortcuts-kubernetes' },
            item_id: :kubernetes
          )
        end

        def terraform_states_menu_item
          unless can?(context.current_user, :read_terraform_state, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :terraform_states)
          end

          ::Sidebars::MenuItem.new(
            title: s_('Terraform|Terraform states'),
            link: project_terraform_index_path(context.project),
            super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::OperationsMenu,
            active_routes: { controller: :terraform },
            item_id: :terraform_states
          )
        end

        def aws_menu_item
          enabled_for_user = Feature.enabled?(:cloudseed_aws, context.current_user)
          enabled_for_group = Feature.enabled?(:cloudseed_aws, context.project.group)
          enabled_for_project = Feature.enabled?(:cloudseed_aws, context.project)
          feature_is_enabled = enabled_for_user || enabled_for_group || enabled_for_project
          user_has_permissions = can?(context.current_user, :admin_project_aws, context.project)

          return ::Sidebars::NilMenuItem.new(item_id: :cloudseed_aws) unless feature_is_enabled && user_has_permissions

          ::Sidebars::MenuItem.new(
            title: _('AWS'),
            link: project_aws_path(context.project),
            super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::OperationsMenu,
            item_id: :aws,
            active_routes: { controller: %w[
              projects/aws/configuration
            ] }
          )
        end

        def google_cloud_menu_item
          user_has_permissions = can?(context.current_user, :admin_project_google_cloud, context.project)
          google_oauth2_configured = google_oauth2_configured?

          unless user_has_permissions && google_oauth2_configured
            return ::Sidebars::NilMenuItem.new(item_id: :incubation_5mp_google_cloud)
          end

          ::Sidebars::MenuItem.new(
            title: _('Google Cloud'),
            link: project_google_cloud_configuration_path(context.project),
            super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::OperationsMenu,
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

        def google_oauth2_configured?
          config = Gitlab::Auth::OAuth::Provider.config_for('google_oauth2')
          config.present? && config.app_id.present? && config.app_secret.present?
        end
      end
    end
  end
end
