# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class PackagesRegistriesMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(packages_registry_menu_item)
          add_item(container_registry_menu_item)
          add_item(dependency_proxy_menu_item)

          true
        end

        override :link
        def link
          renderable_items.first.link
        end

        override :title
        def title
          _('Packages & Registries')
        end

        override :sprite_icon
        def sprite_icon
          'package'
        end

        private

        def packages_registry_menu_item
          unless context.group.packages_feature_enabled?
            return ::Sidebars::NilMenuItem.new(item_id: :packages_registry)
          end

          ::Sidebars::MenuItem.new(
            title: _('Package Registry'),
            link: group_packages_path(context.group),
            active_routes: { controller: 'groups/packages' },
            item_id: :packages_registry
          )
        end

        def container_registry_menu_item
          if !::Gitlab.config.registry.enabled || !can?(context.current_user, :read_container_image, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :container_registry)
          end

          ::Sidebars::MenuItem.new(
            title: _('Container Registry'),
            link: group_container_registries_path(context.group),
            active_routes: { controller: 'groups/registry/repositories' },
            item_id: :container_registry
          )
        end

        def dependency_proxy_menu_item
          unless context.group.dependency_proxy_feature_available?
            return ::Sidebars::NilMenuItem.new(item_id: :dependency_proxy)
          end

          ::Sidebars::MenuItem.new(
            title: _('Dependency Proxy'),
            link: group_dependency_proxy_path(context.group),
            active_routes: { controller: 'groups/dependency_proxies' },
            item_id: :dependency_proxy
          )
        end
      end
    end
  end
end
