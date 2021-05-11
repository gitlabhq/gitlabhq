# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class HiddenMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(activity_menu_item)
          add_item(graph_menu_item)
          add_item(new_issue_menu_item)
          add_item(jobs_menu_item)
          add_item(commits_menu_item)
          add_item(issue_boards_menu_item)

          true
        end

        private

        def activity_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Activity'),
            link: activity_project_path(context.project),
            active_routes: {},
            container_html_options: { class: 'shortcuts-project-activity' },
            item_id: :activity
          )
        end

        def graph_menu_item
          if !can?(context.current_user, :download_code, context.project) ||
            context.project.empty_repo?
            return ::Sidebars::NilMenuItem.new(item_id: :graph)
          end

          ::Sidebars::MenuItem.new(
            title: _('Graph'),
            link: project_network_path(context.project, context.current_ref),
            active_routes: {},
            container_html_options: { class: 'shortcuts-network' },
            item_id: :graph
          )
        end

        def new_issue_menu_item
          unless can?(context.current_user, :read_issue, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :new_issue)
          end

          ::Sidebars::MenuItem.new(
            title: _('Create a new issue'),
            link: new_project_issue_path(context.project),
            active_routes: {},
            container_html_options: { class: 'shortcuts-new-issue' },
            item_id: :new_issue
          )
        end

        def jobs_menu_item
          unless can?(context.current_user, :read_build, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :jobs)
          end

          ::Sidebars::MenuItem.new(
            title: _('Jobs'),
            link: project_jobs_path(context.project),
            active_routes: {},
            container_html_options: { class: 'shortcuts-builds' },
            item_id: :jobs
          )
        end

        def commits_menu_item
          if !can?(context.current_user, :download_code, context.project) ||
            context.project.empty_repo?
            return ::Sidebars::NilMenuItem.new(item_id: :commits)
          end

          ::Sidebars::MenuItem.new(
            title: _('Commits'),
            link: project_commits_path(context.project),
            active_routes: {},
            container_html_options: { class: 'shortcuts-commits' },
            item_id: :commits
          )
        end

        def issue_boards_menu_item
          unless can?(context.current_user, :read_issue, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :issue_boards)
          end

          ::Sidebars::MenuItem.new(
            title: _('Issue Boards'),
            link: project_boards_path(context.project),
            active_routes: {},
            container_html_options: { class: 'shortcuts-issue-boards' },
            item_id: :issue_boards
          )
        end
      end
    end
  end
end
