# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class PasswordMenu < ::Sidebars::Menu
        override :link
        def link
          edit_user_settings_password_path
        end

        override :title
        def title
          _('Password')
        end

        override :sprite_icon
        def sprite_icon
          'lock'
        end

        override :render?
        def render?
          !!context.current_user&.allow_password_authentication?
        end

        override :active_routes
        def active_routes
          { controller: :passwords }
        end

        override :extra_container_html_options
        def extra_container_html_options
          { 'data-testid': 'profile_password_link' }
        end
      end
    end
  end
end
