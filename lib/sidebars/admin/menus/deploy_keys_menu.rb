# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class DeployKeysMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_deploy_keys_path
        end

        override :title
        def title
          s_('Admin|Deploy keys')
        end

        override :sprite_icon
        def sprite_icon
          'key'
        end

        override :active_routes
        def active_routes
          { controller: :deploy_keys }
        end
      end
    end
  end
end
