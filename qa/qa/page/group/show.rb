# frozen_string_literal: true

module QA
  module Page
    module Group
      class Show < Page::Base
        include Page::Component::GroupsFilter
        include QA::Page::Component::ConfirmModal

        view 'app/views/groups/_home_panel.html.haml' do
          element :new_project_button
          element :new_subgroup_button
          element :group_id_content
        end

        view 'app/views/shared/members/_access_request_links.html.haml' do
          element :leave_group_link
          element :request_access_link
        end

        def click_subgroup(name)
          click_link name
        end

        def has_new_project_and_new_subgroup_buttons?
          has_element?(:new_project_button)
          has_element?(:new_subgroup_button)
        end

        def has_subgroup?(name)
          has_filtered_group?(name)
        end

        def go_to_new_subgroup
          click_element :new_subgroup_button
        end

        def go_to_new_project
          click_element :new_project_button
        end

        def group_id
          find_element(:group_id_content).text.delete('Group ID: ').sub(/\n.*/, '')
        end

        def leave_group
          click_element :leave_group_link
          click_confirmation_ok_button
        end

        def click_request_access
          click_element :request_access_link
        end
      end
    end
  end
end
