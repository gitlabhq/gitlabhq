module QA
  module Page
    module Dashboard
      class Groups < Page::Base
        view 'app/views/shared/groups/_search_form.html.haml' do
          element :groups_filter, 'search_field_tag :filter'
          element :groups_filter_placeholder, 'Filter by name...'
        end

        view 'app/views/dashboard/_groups_head.html.haml' do
          element :new_group_button, 'link_to _("New group")'
        end

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
