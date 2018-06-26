module QA
  module Page
    module MergeRequest
      class CompareBeforeNew < Page::Base
        view 'app/views/projects/merge_requests/creations/_new_compare.html.haml' do
          element :source_branch_dropdown, /dropdown_toggle.*Select source branch"/
          element :compare_branches_and_continue, "submit 'Compare branches and continue'"
        end

        def select_source_branch(branch_name)
          find('.dropdown-toggle-text', text: 'Select source branch').click
          click_link branch_name
        end

        def compare_branches_and_continue
          click_on 'Compare branches and continue'
        end
      end
    end
  end
end
