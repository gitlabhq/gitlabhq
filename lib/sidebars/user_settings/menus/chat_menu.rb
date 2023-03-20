# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class ChatMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          profile_chat_names_path
        end

        override :title
        def title
          _('Chat')
        end

        override :sprite_icon
        def sprite_icon
          'comment'
        end

        override :active_routes
        def active_routes
          { controller: :chat_names }
        end
      end
    end
  end
end
