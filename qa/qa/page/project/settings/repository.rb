module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          def select_protected_branch(name)
            within '.new-protected-branch' do
              find('.git-revision-dropdown-toggle').click
              within('.dropdown-input') { first('input').set(name) }
              within('.dropdown-content') { click_link name }
            end
          end

          def select_allowed_to_merge(index)
            select_roles_dropdown_value('.merge_access_levels-container', index)
          end

          def select_allowed_to_push(index)
            select_roles_dropdown_value('.push_access_levels-container', index)
          end

          def protect_branch
            within '#new_protected_branch' do
              find('[name=commit]').click
            end
          end

          private

          def select_roles_dropdown_value(dropdown_locator, index)
            within dropdown_locator do
              find('.dropdown-menu-toggle').click
              within '.dropdown-content' do
                options = find_all('a[data-group="roles"]')
                options[index].click
              end
            end
          end
        end
      end
    end
  end
end
