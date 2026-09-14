# frozen_string_literal: true

module Sidebars
  module Organizations
    module Menus
      class SettingsMenu < ::Sidebars::Menu
        override :title
        def title
          _('Settings')
        end

        override :sprite_icon
        def sprite_icon
          'settings'
        end

        override :pick_into_super_sidebar?
        def pick_into_super_sidebar?
          true
        end
      end
    end
  end
end

Sidebars::Organizations::Menus::SettingsMenu.prepend_mod
