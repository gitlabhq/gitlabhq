# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module Repository
            extend QA::Page::PageConcern

            def self.included(base)
              super

              base.class_eval do
                include QA::Page::Project::SubMenus::SuperSidebar::Common
              end
            end

            def go_to_files
              open_repository_submenu("Files")
            end

            def go_to_repository_commits
              open_repository_submenu("Commits")
            end

            def go_to_repository_branches
              open_repository_submenu("Branches")
            end

            def go_to_repository_tags
              open_repository_submenu("Tags")
            end

            def go_to_snippets
              open_repository_submenu("Snippets")
            end

            def go_to_contributor_statistics
              open_repository_submenu("Contributor statistics")
            end

            def go_to_graph
              open_repository_submenu("Graph")
            end

            def go_to_compare_revisions
              open_repository_submenu("Compare revisions")
            end

            private

            def open_repository_submenu(sub_menu)
              open_submenu("Repository", "#repository", sub_menu)
            end
          end
        end
      end
    end
  end
end
