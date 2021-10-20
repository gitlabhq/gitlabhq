# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ZentaoMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          render?.tap { |render| add_items if render }
        end

        override :link
        def link
          zentao_integration.url
        end

        override :title
        def title
          s_('ZentaoIntegration|ZenTao issues')
        end

        override :title_html_options
        def title_html_options
          {
            id: 'js-onboarding-settings-link'
          }
        end

        override :image_path
        def image_path
          'logos/zentao.svg'
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

        def add_items
          add_item(open_zentao_menu_item)
        end

        private

        def zentao_integration
          @zentao_integration ||= context.project.zentao_integration
        end

        def open_zentao_menu_item
          ::Sidebars::MenuItem.new(
            title: s_('ZentaoIntegration|Open ZenTao'),
            link: zentao_integration.url,
            active_routes: {},
            item_id: :open_zentao,
            sprite_icon: 'external-link',
            container_html_options: {
              target: '_blank',
              rel: 'noopener noreferrer'
            }
          )
        end
      end
    end
  end
end

::Sidebars::Projects::Menus::ZentaoMenu.prepend_mod
