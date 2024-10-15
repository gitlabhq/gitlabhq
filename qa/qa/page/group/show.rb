# frozen_string_literal: true

module QA
  module Page
    module Group
      class Show < Page::Base
        include Layout::Flash
        include Page::Component::GroupsFilter
        include QA::Page::Component::ConfirmModal

        view 'app/views/groups/_home_panel.html.haml' do
          element 'new-project-button'
          element 'new-subgroup-button'
        end

        def click_subgroup(name)
          click_link name
        end

        def has_new_project_and_new_subgroup_buttons?
          has_element?('new_project_button')
          has_element?('new-subgroup-button')
        end

        def has_subgroup?(name)
          has_filtered_group?(name)
        end

        def go_to_new_subgroup
          click_element('new-subgroup-button')
        end

        def go_to_new_project
          click_element 'new-project-button'
        end

        def group_id
          find_element('group-id-content').text.delete('Group ID: ').sub(/\n.*/, '')
        end

        def leave_group
          dismiss_duo_chat_popup if respond_to?(:dismiss_duo_chat_popup)

          click_element 'groups-projects-more-actions-dropdown'
          wait_for_requests

          click_element 'leave-group-link'
          click_confirmation_ok_button
        end

        def click_request_access
          click_element 'groups-projects-more-actions-dropdown'
          wait_for_requests

          click_element 'request-access-link'
        end
      end
    end
  end
end

QA::Page::Group::Show.prepend_mod_with('Page::Component::DuoChatCallout', namespace: QA)
