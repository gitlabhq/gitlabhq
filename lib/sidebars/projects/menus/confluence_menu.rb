# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ConfluenceMenu < ::Sidebars::Menu
        override :link
        def link
          project_wikis_confluence_path(context.project)
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-confluence'
          }
        end

        override :title
        def title
          _('Confluence')
        end

        override :image_path
        def image_path
          'confluence.svg'
        end

        override :image_html_options
        def image_html_options
          {
            alt: title
          }
        end

        override :render?
        def render?
          context.project.has_confluence?
        end
      end
    end
  end
end
