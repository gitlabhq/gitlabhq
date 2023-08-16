# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Groups < Page::Base
        include Page::Component::GroupsFilter

        view 'app/views/dashboard/_groups_head.html.haml' do
          element 'new-group-button'
        end

        def has_group?(name)
          has_filtered_group?(name)
        end

        def click_group(name)
          raise "Group with name #{name} not found!" unless has_group?(name)

          click_link name
        end

        def click_new_group
          click_element('new-group-button')
        end
      end
    end
  end
end
