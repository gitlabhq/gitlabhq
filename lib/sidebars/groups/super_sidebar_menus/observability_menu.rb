# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- This has to be named this way.
module Sidebars
  module Groups
    module SuperSidebarMenus
      class ObservabilityMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Observability')
        end

        override :sprite_icon
        def sprite_icon
          'eye'
        end

        override :configure_menu_items
        def configure_menu_items
          add_item(::Sidebars::NilMenuItem.new(item_id: :o11y_settings))
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
