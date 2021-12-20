# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ShimoMenu < ::Sidebars::Menu
        override :link
        def link
          project_integrations_shimo_path(context.project)
        end

        override :title
        def title
          s_('Shimo|Shimo')
        end

        override :image_path
        def image_path
          'logos/shimo.svg'
        end

        override :image_html_options
        def image_html_options
          {
            size: 16
          }
        end

        override :render?
        def render?
          context.project.has_shimo?
        end

        override :active_routes
        def active_routes
          { controller: :shimo }
        end
      end
    end
  end
end
