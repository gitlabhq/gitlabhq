module QA
  module Page
    module Group
      class Show < Page::Base
        view 'app/views/groups/show.html.haml' do
          element :new_project_or_subgroup_dropdown, '.new-project-subgroup'
          element :new_project_or_subgroup_dropdown_toggle, '.dropdown-toggle'
          element :new_project_option, /%li.*data:.*value: "new-project"/
          element :new_project_button, /%input.*data:.*action: "new-project"/
          element :new_subgroup_option, /%li.*data:.*value: "new-subgroup"/

          # data-value and data-action get modified by JS for subgroup
          element :new_subgroup_button, /%input.*\.js-new-group-child/
        end

        view 'app/assets/javascripts/groups/constants.js' do
          element :no_result_text, 'Sorry, no groups or projects matched your search'
        end

        def go_to_subgroup(name)
          click_link name
        end

        def filter_by_name(name)
          fill_in 'Filter by name...', with: name
        end

        def has_subgroup?(name)
          filter_by_name(name)

          wait(reload: false) do
            return false if page.has_content?('Sorry, no groups or projects matched your search')

            page.has_link?(name)
          end
        end

        def go_to_new_subgroup
          click_new('subgroup')

          find("input[data-action='new-subgroup']").click
        end

        def go_to_new_project
          click_new('project')

          find("input[data-action='new-project']").click
        end

        private

        def click_new(kind)
          within '.new-project-subgroup' do
            css = "li[data-value='new-#{kind}']"

            # May need to click again because it is possible to click the button quicker than the JS is bound
            wait(reload: false) do
              find('.dropdown-toggle').click

              page.has_css?(css)
            end

            find(css).click
          end
        end
      end
    end
  end
end
