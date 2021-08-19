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
          can?(context.current_user, :read_cluster, context.group)
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
      end
    end
  end
end
