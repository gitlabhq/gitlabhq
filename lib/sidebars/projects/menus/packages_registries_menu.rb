# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class PackagesRegistriesMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(packages_registry_menu_item)
          add_item(container_registry_menu_item)
          add_item(infrastructure_registry_menu_item)
          add_item(harbor_registry_menu_item)
          add_item(model_experiments_menu_item)
          add_item(model_registry_menu_item)
          true
        end

        override :title
        def title
          _('Packages and registries')
        end

        override :sprite_icon
        def sprite_icon
          'package'
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def packages_registry_menu_item
          if packages_registry_disabled?
            return ::Sidebars::NilMenuItem.new(item_id: :packages_registry)
          end

          ::Sidebars::MenuItem.new(
            title: _('Package Registry'),
            link: project_packages_path(context.project),
            super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::DeployMenu,
            active_routes: { controller: :packages },
            item_id: :packages_registry,
            container_html_options: { class: 'shortcuts-container-registry' }
          )
        end

        def container_registry_menu_item
          if container_registry_unavailable?
            return ::Sidebars::NilMenuItem.new(item_id: :container_registry)
          end

          ::Sidebars::MenuItem.new(
            title: _('Container Registry'),
            link: project_container_registry_index_path(context.project),
            super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::DeployMenu,
            active_routes: { controller: 'projects/registry/repositories' },
            item_id: :container_registry
          )
        end

        def infrastructure_registry_menu_item
          if packages_registry_disabled?
            return ::Sidebars::NilMenuItem.new(item_id: :infrastructure_registry)
          end

          ::Sidebars::MenuItem.new(
            title: _('Terraform modules'),
            link: project_infrastructure_registry_index_path(context.project),
            super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::OperationsMenu,
            active_routes: { controller: :infrastructure_registry },
            item_id: :infrastructure_registry
          )
        end

        def harbor_registry_menu_item
          if context.project.harbor_integration.nil? ||
              !context.project.harbor_integration.activated?
            return ::Sidebars::NilMenuItem.new(item_id: :harbor_registry)
          end

          ::Sidebars::MenuItem.new(
            title: _('Harbor Registry'),
            link: project_harbor_repositories_path(context.project),
            super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::DeployMenu,
            active_routes: { controller: 'projects/harbor/repositories' },
            item_id: :harbor_registry
          )
        end

        def model_experiments_menu_item
          unless can?(context.current_user, :read_model_experiments, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :model_experiments)
          end

          ::Sidebars::MenuItem.new(
            title: _('Model experiments'),
            link: project_ml_experiments_path(context.project),
            super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::AnalyzeMenu,
            active_routes: { controller: %w[projects/ml/experiments projects/ml/candidates] },
            item_id: :model_experiments
          )
        end

        def model_registry_menu_item
          unless can?(context.current_user, :read_model_registry, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :model_registry)
          end

          ::Sidebars::MenuItem.new(
            title: _('Model registry'),
            link: project_ml_models_path(context.project),
            super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::DeployMenu,
            active_routes: { controller: %w[projects/ml/models] },
            item_id: :model_registry
          )
        end

        def packages_registry_disabled?
          !::Gitlab.config.packages.enabled ||
            !can?(context.current_user, :read_package, context.project&.packages_policy_subject)
        end

        def container_registry_unavailable?
          !::Gitlab.config.registry.enabled ||
            !can?(context.current_user, :read_container_image, context.project)
        end
      end
    end
  end
end

Sidebars::Projects::Menus::PackagesRegistriesMenu.prepend_mod_with('Sidebars::Projects::Menus::PackagesRegistriesMenu')
