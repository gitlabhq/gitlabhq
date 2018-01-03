module QA
  module Page
    module Dashboard
      class Groups < Page::Base
        def filter_by_name(name)
          fill_in 'Filter by name...', with: name
        end

        def has_group?(name)
          filter_by_name(name)

          page.has_link?(name)
        end

        def go_to_group(name)
          click_link name
        end

        def go_to_new_group
          click_on 'New group'
        end
      end
    end
  end
end
