# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class KubernetesMenu < ::Sidebars::Menu
        override :link
        def link
          group_clusters_path(context.group)
        end

        override :title
        def title
          _('Kubernetes')
        end

        override :sprite_icon
        def sprite_icon
          'cloud-gear'
        end

        override :render?
        def render?
          clusterable = context.group

          clusterable.certificate_based_clusters_enabled? &&
            can?(context.current_user, :read_cluster, clusterable)
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-kubernetes'
          }
        end

        override :active_routes
        def active_routes
          { controller: :clusters }
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.merge({
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::OperationsMenu,
            item_id: :group_kubernetes_clusters
          })
        end
      end
    end
  end
end
