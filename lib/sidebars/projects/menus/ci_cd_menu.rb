# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class CiCdMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return unless can?(context.current_user, :read_build, context.project)

          add_item(pipelines_menu_item)
          add_item(pipelines_editor_menu_item)
          add_item(jobs_menu_item)
          add_item(artifacts_menu_item)
          add_item(pipeline_schedules_menu_item)
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-pipelines'
          }
        end

        override :title
        def title
          _('CI/CD')
        end

        override :sprite_icon
        def sprite_icon
          'rocket'
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def pipelines_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Pipelines'),
            link: project_pipelines_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::BuildMenu,
            container_html_options: { class: 'shortcuts-pipelines' },
            active_routes: { path: pipelines_routes },
            item_id: :pipelines
          )
        end

        def pipelines_routes
          %w[
            pipelines#index
            pipelines#show
            pipelines#new
            pipelines#dag
            pipelines#failures
            pipelines#builds
            pipelines#test_report
          ]
        end

        def pipelines_editor_menu_item
          unless context.can_view_pipeline_editor
            return ::Sidebars::NilMenuItem.new(item_id: :pipelines_editor)
          end

          params = {
            branch_name: context.current_ref || context.project.default_branch
          }

          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Pipeline editor') : s_('Pipelines|Editor'),
            link: project_ci_pipeline_editor_path(context.project, params),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::BuildMenu,
            active_routes: { path: 'projects/ci/pipeline_editor#show' },
            item_id: :pipelines_editor
          )
        end

        def jobs_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Jobs'),
            link: project_jobs_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::BuildMenu,
            container_html_options: { class: 'shortcuts-builds' },
            active_routes: { controller: :jobs },
            item_id: :jobs
          )
        end

        def artifacts_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Artifacts'),
            link: project_artifacts_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::BuildMenu,
            container_html_options: { class: 'shortcuts-builds' },
            active_routes: { path: 'artifacts#index' },
            item_id: :artifacts
          )
        end

        def pipeline_schedules_menu_item
          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Pipeline schedules') : _('Schedules'),
            link: pipeline_schedules_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::BuildMenu,
            container_html_options: { class: 'shortcuts-builds' },
            active_routes: { controller: :pipeline_schedules },
            item_id: :pipeline_schedules
          )
        end
      end
    end
  end
end

Sidebars::Projects::Menus::CiCdMenu.prepend_mod_with('Sidebars::Projects::Menus::CiCdMenu')
