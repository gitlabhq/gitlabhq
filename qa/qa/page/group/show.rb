module QA
  module Page
    module Group
      class Show < Page::Base
        ##
        # TODO, define all selectors required by this page object
        #
        # See gitlab-org/gitlab-qa#154
        #
        view 'app/views/groups/show.html.haml'

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
          within '.new-project-subgroup' do
            find('.dropdown-toggle').click
            find("li[data-value='new-subgroup']").click
          end

          find("input[data-action='new-subgroup']").click
        end

        def go_to_new_project
          within '.new-project-subgroup' do
            find('.dropdown-toggle').click
            find("li[data-value='new-project']").click
          end

          find("input[data-action='new-project']").click
        end
      end
    end
  end
end
