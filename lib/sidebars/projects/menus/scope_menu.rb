# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ScopeMenu < ::Sidebars::Menu
        override :link
        def link
          project_path(context.project)
        end

        override :title
        def title
          context.project.name
        end

        override :active_routes
        def active_routes
          { path: 'projects#show' }
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-project'
          }
        end

        override :render?
        def render?
          true
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.merge({
            avatar: context.project.avatar_url,
            entity_id: context.project.id,
            super_sidebar_parent: ::Sidebars::StaticMenu,
            item_id: :project_overview
          })
        end
      end
    end
  end
end
