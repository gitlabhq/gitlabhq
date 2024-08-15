# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Groups < Page::Base
        include Page::Component::GroupsFilter

        view 'app/views/dashboard/_groups_head.html.haml' do
          element 'new-group-button'
        end

        view 'app/views/dashboard/groups/index.html.haml' do
          element 'groups-empty-state'
        end

        def has_group?(name)
          return false if has_element?('groups-empty-state', wait: 5)

          has_filtered_group?(name)
        end

        def click_group(name)
          raise "Group with name #{name} not found!" unless has_group?(name)

          click_link name
        end

        def click_new_group
          dismiss_duo_chat_popup if respond_to?(:dismiss_duo_chat_popup)

          click_element('new-group-button')
        end
      end
    end
  end
end

QA::Page::Dashboard::Groups.prepend_mod_with('Page::Component::DuoChatCallout', namespace: QA)
