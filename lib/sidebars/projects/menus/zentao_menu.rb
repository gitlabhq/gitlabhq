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

        override :title_html_options
        def title_html_options
          {
            id: 'js-onboarding-settings-link'
          }
        end

        override :sprite_icon
        def sprite_icon
          'external-link'
        end

        # Hardcode sizes so image doesn't flash before CSS loads https://gitlab.com/gitlab-org/gitlab/-/issues/321022
        override :image_html_options
        def image_html_options
          {
            size: 16
          }
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
