# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class CiCdMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(runners_menu_item)

          true
        end

        override :link
        def link
          renderable_items.first.link
        end

        override :title
        def title
          _('CI/CD')
        end

        override :sprite_icon
        def sprite_icon
          'rocket'
        end

        private

        def runners_menu_item
          return ::Sidebars::NilMenuItem.new(item_id: :runners) unless show_runners?

          ::Sidebars::MenuItem.new(
            title: _('Runners'),
            link: group_runners_path(context.group),
            active_routes: { path: 'groups/runners#index' },
            item_id: :runners
          )
        end

        # TODO Proper policies, such as `read_group_runners`, should be implemented per
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/334802
        def show_runners?
          can?(context.current_user, :admin_group, context.group) &&
            Feature.enabled?(:runner_list_group_view_vue_ui, context.group, default_enabled: :yaml)
        end
      end
    end
  end
end
