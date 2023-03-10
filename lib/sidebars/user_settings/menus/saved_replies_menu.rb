# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class SavedRepliesMenu < ::Sidebars::Menu
        include UsersHelper

        override :link
        def link
          profile_saved_replies_path
        end

        override :title
        def title
          _('Saved Replies')
        end

        override :sprite_icon
        def sprite_icon
          'symlink'
        end

        override :render?
        def render?
          !!context.current_user && saved_replies_enabled?
        end

        override :active_routes
        def active_routes
          { controller: :saved_replies }
        end

        private

        def current_user
          context.current_user
        end
      end
    end
  end
end
