# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class KubernetesMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_clusters_path
        end

        override :title
        def title
          s_('Admin|Kubernetes')
        end

        override :sprite_icon
        def sprite_icon
          'cloud-gear'
        end

        override :render?
        def render?
          current_user && current_user.can_admin_all_resources? && instance_clusters_enabled?
        end

        override :active_routes
        def active_routes
          { controller: :clusters }
        end
      end
    end
  end
end
