# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- This has to be named this way.
module Sidebars
  module Groups
    module SuperSidebarMenus
      class ObservabilityMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Observe')
        end

        override :sprite_icon
        def sprite_icon
          'eye'
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
