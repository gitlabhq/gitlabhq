module QA
  module Page
    module Group
      class Show < Page::Base
        view 'app/views/groups/show.html.haml' do
          element :dropdown_toggle, '.dropdown-toggle'
          element :new_project_subgroup, '.new-project-subgroup'

          element :new_project_toggle,
            /%li.+ data: { value: "new\-project"/
          element :new_project_button,
            /%input.+ data: { action: "new\-project"/

          element :new_subgroup_toggle,
            /%li.+ data: { value: "new\-subgroup"/
          # TODO: input[data-action='new-subgroup'] seems to be handled by JS?
          # See app/assets/javascripts/groups/new_group_child.js
        end

        view 'app/views/shared/groups/_search_form.html.haml' do
          element :filter_by_name,
            "placeholder: s_('GroupsTree|Filter by name...')"
        end

        def go_to_subgroup(name)
          click_link name
        end

        def filter_by_name(name)
          fill_in 'Filter by name...', with: name
        end

        def has_subgroup?(name)
          filter_by_name(name)

          page.has_link?(name)
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
