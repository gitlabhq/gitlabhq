# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class AccessTokensMenu < ::Sidebars::Menu
        override :link
        def link
          user_settings_personal_access_tokens_path
        end

        override :title
        def title
          _('Access tokens')
        end

        override :sprite_icon
        def sprite_icon
          'token'
        end

        override :render?
        def render?
          return false unless context.current_user
          return false if Gitlab::CurrentSettings.personal_access_tokens_disabled?

          true
        end

        override :active_routes
        def active_routes
          { controller: :personal_access_tokens }
        end

        override :extra_container_html_options
        def extra_container_html_options
          { 'data-testid': 'access_token_link' }
        end
      end
    end
  end
end

Sidebars::UserSettings::Menus::AccessTokensMenu.prepend_mod
