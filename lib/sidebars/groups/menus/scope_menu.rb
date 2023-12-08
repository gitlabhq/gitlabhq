# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class ScopeMenu < ::Sidebars::Menu
        override :link
        def link
          group_path(context.group)
        end

        override :title
        def title
          context.group.name
        end

        override :active_routes
        def active_routes
          { path: %w[groups#show groups#details groups#new projects#new] }
        end

        override :render?
        def render?
          true
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.merge({
            avatar: context.group.avatar_url,
            entity_id: context.group.id,
            super_sidebar_parent: ::Sidebars::StaticMenu,
            item_id: :group_overview
          })
        end
      end
    end
  end
end
