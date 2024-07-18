# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class MessagesMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_broadcast_messages_path
        end

        override :title
        def title
          s_('Admin|Messages')
        end

        override :sprite_icon
        def sprite_icon
          'bullhorn'
        end

        override :active_routes
        def active_routes
          { controller: :broadcast_messages }
        end
      end
    end
  end
end
