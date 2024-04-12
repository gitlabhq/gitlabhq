# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class SshKeysMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          user_settings_ssh_keys_path
        end

        override :title
        def title
          _('SSH Keys')
        end

        override :sprite_icon
        def sprite_icon
          'key'
        end

        override :active_routes
        def active_routes
          { controller: :ssh_keys }
        end

        override :extra_container_html_options
        def extra_container_html_options
          { 'data-testid': 'ssh_keys_link' }
        end
      end
    end
  end
end
