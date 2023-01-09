# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class ObservabilityMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(dashboards_menu_item)
          add_item(explore_menu_item)
          add_item(datasources_menu_item)
          add_item(manage_menu_item)
        end

        override :title
        def title
          _('Observability')
        end

        override :sprite_icon
        def sprite_icon
          'monitor'
        end

        override :render?
        def render?
          Gitlab::Observability.observability_enabled?(context.current_user, context.group)
        end

        private

        def dashboards_menu_item
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Dashboards'),
            link: group_observability_dashboards_path(context.group),
            active_routes: { path: 'groups/observability#dashboards' },
            item_id: :dashboards
          )
        end

        def explore_menu_item
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Explore'),
            link: group_observability_explore_path(context.group),
            active_routes: { path: 'groups/observability#explore' },
            item_id: :explore
          )
        end

        def datasources_menu_item
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Data sources'),
            link: group_observability_datasources_path(context.group),
            active_routes: { path: 'groups/observability#datasources' },
            item_id: :datasources
          )
        end

        def manage_menu_item
          ::Sidebars::MenuItem.new(
            title: s_('Observability|Manage dashboards'),
            link: group_observability_manage_path(context.group),
            active_routes: { path: 'groups/observability#manage' },
            item_id: :manage
          )
        end
      end
    end
  end
end
