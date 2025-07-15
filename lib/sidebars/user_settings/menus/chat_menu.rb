# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class ChatMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          user_settings_integration_accounts_path
        end

        override :title
        def title
          s_('Integrations|Integration accounts')
        end

        override :sprite_icon
        def sprite_icon
          'connected'
        end

        override :active_routes
        def active_routes
          { controller: :chat_names }
        end
      end
    end
  end
end
