# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Repository
        module MenuItems
          class Commits < ::Sidebars::MenuItem
            override :link
            def link
              project_commits_path(context.project, context.current_ref)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                id: 'js-onboarding-commits-link'
              }
            end

            override :active_routes
            def active_routes
              { controller: %w(commit commits) }
            end

            override :title
            def title
              _('Commits')
            end
          end
        end
      end
    end
  end
end
