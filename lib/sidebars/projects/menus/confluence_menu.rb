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

        override :render?
        def render?
          context.project.has_confluence?
        end

        override :active_routes
        def active_routes
          { controller: :confluences }
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.merge({
            item_id: :confluence,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu
          })
        end
      end
    end
  end
end
