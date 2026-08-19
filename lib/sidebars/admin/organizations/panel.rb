# frozen_string_literal: true

module Sidebars
  module Admin
    module Organizations
      class Panel < ::Sidebars::Panel
        override :configure_menus
        def configure_menus
          super
          add_menu(Sidebars::Admin::Organizations::Menus::OverviewMenu.new(context))
        end

        override :aria_label
        def aria_label
          s_('Organization|Organization administration')
        end

        override :super_sidebar_context_header
        def super_sidebar_context_header
          aria_label
        end
      end
    end
  end
end

Sidebars::Admin::Organizations::Panel.prepend_mod
