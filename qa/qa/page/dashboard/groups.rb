module QA
  module Page
    module Dashboard
      class Groups < Page::Base
        include Page::Component::GroupsFilter

        view 'app/views/dashboard/_groups_head.html.haml' do
          element :new_group_button, 'link_to _("New group")'
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
