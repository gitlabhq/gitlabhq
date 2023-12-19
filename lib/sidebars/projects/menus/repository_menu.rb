# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class RepositoryMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false unless can?(context.current_user, :read_code, context.project)
          return false if context.project.empty_repo?

          add_item(files_menu_item)
          add_item(commits_menu_item)
          add_item(branches_menu_item)
          add_item(tags_menu_item)
          add_item(contributors_menu_item)
          add_item(graphs_menu_item)
          add_item(compare_menu_item)

          true
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-tree'
          }
        end

        override :title
        def title
          _('Repository')
        end

        override :sprite_icon
        def sprite_icon
          'doc-text'
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def files_menu_item
          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Repository') : _('Files'),
            link: project_tree_path(context.project, context.current_ref),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::CodeMenu,
            active_routes: { controller: %w[tree blob blame edit_tree new_tree find_file] },
            container_html_options: { class: 'shortcuts-tree' },
            item_id: :files
          )
        end

        def commits_menu_item
          link = project_commits_path(context.project, context.current_ref, ref_type: ref_type_from_context(context))

          ::Sidebars::MenuItem.new(
            title: _('Commits'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::CodeMenu,
            active_routes: { controller: %w[commit commits] },
            item_id: :commits,
            container_html_options: { class: 'shortcuts-commits' }
          )
        end

        def branches_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Branches'),
            link: project_branches_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::CodeMenu,
            active_routes: { controller: :branches },
            item_id: :branches
          )
        end

        def tags_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Tags'),
            link: project_tags_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::CodeMenu,
            item_id: :tags,
            active_routes: { controller: :tags }
          )
        end

        def contributors_menu_item
          return false unless context.project.analytics_enabled?

          link = project_graph_path(context.project, context.current_ref, ref_type: ref_type_from_context(context))

          ::Sidebars::MenuItem.new(
            title: _('Contributor analytics'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::AnalyzeMenu,
            active_routes: { path: 'graphs#show' },
            item_id: :contributors
          )
        end

        def graphs_menu_item
          link = project_network_path(context.project, context.current_ref, ref_type: ref_type_from_context(context))

          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Repository graph') : _('Graph'),
            link: link,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::CodeMenu,
            active_routes: { controller: :network },
            container_html_options: { class: 'shortcuts-network' },
            item_id: :graphs
          )
        end

        def compare_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Compare revisions'),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::CodeMenu,
            link: project_compare_index_path(context.project, from: context.project.repository.root_ref, to: context.current_ref),
            active_routes: { controller: :compare },
            item_id: :compare
          )
        end

        def ref_type_from_context(context)
          ref_type = context.try(:ref_type)
          ref_type ||= 'heads' if context.current_ref == context.project.repository.root_ref
          ref_type
        end
      end
    end
  end
end

Sidebars::Projects::Menus::RepositoryMenu.prepend_mod_with('Sidebars::Projects::Menus::RepositoryMenu')
