# frozen_string_literal: true

module Sidebars # rubocop:disable Gitlab/BoundedContexts -- Sidebar menus follow the existing Sidebars::Admin::Menus namespace
  module Admin
    module Menus
      class ObservabilityMenu < ::Sidebars::Menu
        override :link
        def link
          admin_o11y_service_settings_path
        end

        override :title
        def title
          s_('Admin|Observability')
        end

        override :sprite_icon
        def sprite_icon
          'eye'
        end

        override :render?
        def render?
          !!current_user&.can_admin_all_resources?
        end

        override :active_routes
        def active_routes
          { controller: :o11y_service_settings }
        end
      end
    end
  end
end
