# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module ProjectOverview
        class Menu < ::Sidebars::Menu
          override :configure_menu_items
          def configure_menu_items
            add_item(MenuItems::Details.new(context))
            add_item(MenuItems::Activity.new(context))
            add_item(MenuItems::Releases.new(context))
          end

          override :link
          def link
            project_path(context.project)
          end

          override :extra_container_html_options
          def extra_container_html_options
            {
              class: 'shortcuts-project rspec-project-link'
            }
          end

          override :extra_container_html_options
          def nav_link_html_options
            { class: 'home' }
          end

          override :title
          def title
            _('Project overview')
          end

          override :sprite_icon
          def sprite_icon
            'home'
          end
        end
      end
    end
  end
end
