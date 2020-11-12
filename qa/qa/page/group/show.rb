# frozen_string_literal: true

module QA
  module Page
    module Group
      class Show < Page::Base
        include Page::Component::GroupsFilter

        view 'app/views/groups/_home_panel.html.haml' do
          element :new_project_button
          element :new_subgroup_button
        end

        view 'app/assets/javascripts/groups/constants.js' do
          element :no_result_text, 'No groups or projects matched your search' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/shared/members/_access_request_links.html.haml' do
          element :leave_group_link
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

        def leave_group
          accept_alert do
            click_element :leave_group_link
          end
        end
      end
    end
  end
end
