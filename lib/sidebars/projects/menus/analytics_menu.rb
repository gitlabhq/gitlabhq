# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class AnalyticsMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :configure_menu_items
        def configure_menu_items
          return false unless can?(context.current_user, :read_analytics, context.project)

          add_item(cycle_analytics_menu_item)
          add_item(ci_cd_analytics_menu_item)
          add_item(repository_analytics_menu_item)

          true
        end

        override :link
        def link
          return cycle_analytics_menu_item.link if cycle_analytics_menu_item.render?

          super
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-analytics'
          }
        end

        override :title
        def title
          _('Analytics')
        end

        override :sprite_icon
        def sprite_icon
          'chart'
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def ci_cd_analytics_menu_item
          if !context.project.feature_available?(:builds, context.current_user) ||
              !can?(context.current_user, :read_build, context.project) ||
              !can?(context.current_user, :read_ci_cd_analytics, context.project) ||
              context.project.empty_repo?
            return ::Sidebars::NilMenuItem.new(item_id: :ci_cd_analytics)
          end

          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('CI/CD analytics') : _('CI/CD'),
            link: charts_project_pipelines_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::AnalyzeMenu,
            active_routes: { path: 'pipelines#charts' },
            item_id: :ci_cd_analytics
          )
        end

        def repository_analytics_menu_item
          if context.project.empty_repo? || !can?(context.current_user, :read_repository_graphs, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :repository_analytics)
          end

          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Repository analytics') : _('Repository'),
            link: charts_project_graph_path(context.project, context.current_ref),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::AnalyzeMenu,
            container_html_options: { class: 'shortcuts-repository-charts' },
            active_routes: { path: 'graphs#charts' },
            item_id: :repository_analytics
          )
        end

        def cycle_analytics_menu_item
          strong_memoize(:cycle_analytics_menu_item) do
            unless can?(context.current_user, :read_cycle_analytics, context.project)
              next ::Sidebars::NilMenuItem.new(item_id: :cycle_analytics)
            end

            ::Sidebars::MenuItem.new(
              title: context.is_super_sidebar ? _('Value stream analytics') : _('Value stream'),
              link: project_cycle_analytics_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::AnalyzeMenu,
              container_html_options: { class: 'shortcuts-project-cycle-analytics' },
              active_routes: { path: 'cycle_analytics#show' },
              item_id: :cycle_analytics
            )
          end
        end
      end
    end
  end
end

Sidebars::Projects::Menus::AnalyticsMenu.prepend_mod_with('Sidebars::Projects::Menus::AnalyticsMenu')
