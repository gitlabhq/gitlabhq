# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class PackagesRegistriesMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(packages_registry_menu_item)
          add_item(container_registry_menu_item)
          add_item(infrastructure_registry_menu_item)
          add_item(harbor_registry_menu_item)
          add_item(dependency_proxy_menu_item)
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
          return nil_menu_item(:packages_registry) unless context.group.packages_feature_enabled?

          ::Sidebars::MenuItem.new(
            title: _('Package Registry'),
            link: group_packages_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::DeployMenu,
            active_routes: { controller: 'groups/packages' },
            item_id: :packages_registry
          )
        end

        def container_registry_menu_item
          if !::Gitlab.config.registry.enabled || !can?(context.current_user, :read_container_image, context.group)
            return nil_menu_item(:container_registry)
          end

          ::Sidebars::MenuItem.new(
            title: _('Container Registry'),
            link: group_container_registries_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::DeployMenu,
            active_routes: { controller: 'groups/registry/repositories' },
            item_id: :container_registry
          )
        end

        def infrastructure_registry_menu_item
          return nil_menu_item(:infrastructure_registry) unless context.group.packages_feature_enabled?

          ::Sidebars::MenuItem.new(
            title: _('Terraform modules'),
            link: group_infrastructure_registry_index_path(context.group),
            super_sidebar_parent: Sidebars::Groups::SuperSidebarMenus::OperationsMenu,
            active_routes: { controller: :infrastructure_registry },
            item_id: :infrastructure_registry
          )
        end

        def harbor_registry_menu_item
          if context.group.harbor_integration.nil? ||
              !context.group.harbor_integration.activated?
            return nil_menu_item(:harbor_registry)
          end

          ::Sidebars::MenuItem.new(
            title: _('Harbor Registry'),
            link: group_harbor_repositories_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::DeployMenu,
            active_routes: { controller: 'groups/harbor/repositories' },
            item_id: :harbor_registry
          )
        end

        def dependency_proxy_menu_item
          setting_does_not_exist_or_is_enabled = !context.group.dependency_proxy_setting ||
            context.group.dependency_proxy_setting.enabled

          return nil_menu_item(:dependency_proxy) unless can?(context.current_user, :read_dependency_proxy, context.group)
          return nil_menu_item(:dependency_proxy) unless setting_does_not_exist_or_is_enabled

          ::Sidebars::MenuItem.new(
            title: _('Dependency Proxy'),
            link: group_dependency_proxy_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::OperationsMenu,
            active_routes: { controller: 'groups/dependency_proxies' },
            item_id: :dependency_proxy
          )
        end

        def nil_menu_item(item_id)
          ::Sidebars::NilMenuItem.new(item_id: item_id)
        end
      end
    end
  end
end
