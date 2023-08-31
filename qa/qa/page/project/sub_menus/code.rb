# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Code
          extend QA::Page::PageConcern

          def go_to_repository
            open_code_submenu('Repository')
          end

          def go_to_repository_commits
            open_code_submenu('Commits')
          end

          def go_to_repository_branches
            open_code_submenu('Branches')
          end

          def go_to_repository_tags
            open_code_submenu('Tags')
          end

          def go_to_snippets
            open_code_submenu('Snippets')
          end

          def go_to_graph
            open_code_submenu('Repository graph')
          end

          def go_to_compare_revisions
            open_code_submenu('Compare revisions')
          end

          def go_to_merge_requests
            open_code_submenu('Merge requests')
          end

          private

          def open_code_submenu(sub_menu)
            open_submenu('Code', sub_menu)
          end
        end
      end
    end
  end
end
