require 'pry'

module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          def select_protected_branch(name)
            fill_in 'protected_branch_name', with: name
          end

          def select_allowed_to_merge(index)
            within '.merge_access_levels-container' do
              options = find_all 'a[data-group="roles"]'
              options[index].click
            end
          end

          def select_allowed_to_push(index)
            within '.push_Access_levels-container' do
              options = find_all 'a[data-group="roles"]'
              options[index].click
            end
          end

          def protect_branch
            within '#new_protected_branch' do
              binding.pry
              click_button 'Protect'
            end
          end
        end
      end
    end
  end
end
