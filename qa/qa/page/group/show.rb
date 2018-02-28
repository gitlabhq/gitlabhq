module QA
  module Page
    module Group
      class Show < Page::Base
        def go_to_subgroups
          click_link 'Subgroups'
        end

        def go_to_subgroup(name)
          click_link name
        end

        def has_subgroup?(name)
          page.has_link?(name)
        end

        def go_to_new_subgroup
          click_on 'New Subgroup'
        end

        def go_to_new_project
          click_on 'New Project'
        end
      end
    end
  end
end
