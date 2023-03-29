# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class SnippetsMenu < ::Sidebars::Menu
        override :link
        def link
          project_snippets_path(context.project)
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-snippets'
          }
        end

        override :title
        def title
          _('Snippets')
        end

        override :sprite_icon
        def sprite_icon
          'snippet'
        end

        override :render?
        def render?
          can?(context.current_user, :read_snippet, context.project)
        end

        override :active_routes
        def active_routes
          { controller: :snippets }
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.deep_merge({
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::CodeMenu,
            item_id: :project_snippets
          })
        end
      end
    end
  end
end
