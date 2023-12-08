# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ZentaoMenu < ::Sidebars::Menu
        override :link
        def link
          zentao_integration.url
        end

        override :title
        def title
          s_('ZentaoIntegration|ZenTao')
        end

        override :sprite_icon
        def sprite_icon
          'external-link'
        end

        override :render?
        def render?
          return false if zentao_integration.blank?

          zentao_integration.active?
        end

        private

        def zentao_integration
          @zentao_integration ||= context.project.zentao_integration
        end
      end
    end
  end
end

::Sidebars::Projects::Menus::ZentaoMenu.prepend_mod
