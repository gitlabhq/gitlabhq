# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Repository
        module MenuItems
          class Branches < ::Sidebars::MenuItem
            override :link
            def link
              project_branches_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                id: 'js-onboarding-branches-link'
              }
            end

            override :active_routes
            def active_routes
              { controller: :branches }
            end

            override :title
            def title
              _('Branches')
            end
          end
        end
      end
    end
  end
end
