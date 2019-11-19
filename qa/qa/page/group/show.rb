# frozen_string_literal: true

module QA
  module Page
    module Group
      class Show < Page::Base
        include Page::Component::GroupsFilter

        view 'app/views/groups/_home_panel.html.haml' do
          element :new_project_or_subgroup_dropdown
          element :new_project_or_subgroup_dropdown_toggle
          element :new_project_option
          element :new_subgroup_option
          element :new_in_group_button
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

        def has_new_project_or_subgroup_dropdown?
          has_element?(:new_project_or_subgroup_dropdown)
        end

        def has_subgroup?(name)
          has_filtered_group?(name)
        end

        def go_to_new_subgroup
          select_kind :new_subgroup_option

          click_element :new_in_group_button
        end

        def go_to_new_project
          select_kind :new_project_option

          click_element :new_in_group_button
        end

        def leave_group
          accept_alert do
            click_element :leave_group_link
          end
        end

        private

        def select_kind(kind)
          QA::Support::Retrier.retry_on_exception(sleep_interval: 1.0) do
            within_element(:new_project_or_subgroup_dropdown) do
              # May need to click again because it is possible to click the button quicker than the JS is bound
              wait(reload: false) do
                click_element :new_project_or_subgroup_dropdown_toggle

                has_element?(kind)
              end

              click_element kind
            end
          end
        end
      end
    end
  end
end
