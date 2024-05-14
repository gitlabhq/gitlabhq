# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class GpgKeysMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          user_settings_gpg_keys_path
        end

        override :title
        def title
          _('GPG Keys')
        end

        override :sprite_icon
        def sprite_icon
          'key'
        end

        override :active_routes
        def active_routes
          { controller: :gpg_keys }
        end
      end
    end
  end
end
