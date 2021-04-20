# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Repository
        class Menu < ::Sidebars::Menu
          override :configure_menu_items
          def configure_menu_items
            add_item(MenuItems::Files.new(context))
            add_item(MenuItems::Commits.new(context))
            add_item(MenuItems::Branches.new(context))
            add_item(MenuItems::Tags.new(context))
            add_item(MenuItems::Contributors.new(context))
            add_item(MenuItems::Graphs.new(context))
            add_item(MenuItems::Compare.new(context))
          end

          override :link
          def link
            project_tree_path(context.project)
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

          override :title_html_options
          def title_html_options
            {
              id: 'js-onboarding-repo-link'
            }
          end

          override :sprite_icon
          def sprite_icon
            'doc-text'
          end

          override :render?
          def render?
            can?(context.current_user, :download_code, context.project) &&
              !context.project.empty_repo?
          end
        end
      end
    end
  end
end

Sidebars::Projects::Menus::Repository::Menu.prepend_if_ee('EE::Sidebars::Projects::Menus::Repository::Menu')
