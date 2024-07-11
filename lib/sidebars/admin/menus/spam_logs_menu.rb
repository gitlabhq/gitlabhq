# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class SpamLogsMenu < ::Sidebars::Menu
        override :link
        def link
          admin_spam_logs_path
        end

        override :title
        def title
          s_('Admin|Spam logs')
        end

        override :sprite_icon
        def sprite_icon
          'spam'
        end

        override :render?
        def render?
          current_user && current_user.can_admin_all_resources? && anti_spam_service_enabled?
        end

        override :active_routes
        def active_routes
          { controller: :spam_logs }
        end
      end
    end
  end
end
