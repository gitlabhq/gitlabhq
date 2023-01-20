# frozen_string_literal: true

module QA
  module Page
    module Group
      class Members < Page::Base
        include Page::Component::InviteMembersModal
        include Page::Component::MembersFilter

        view 'app/assets/javascripts/members/components/modals/remove_member_modal.vue' do
          element :remove_member_modal
          element :remove_member_button
        end

        view 'app/assets/javascripts/pages/groups/group_members/index.js' do
          element :member_row
          element :groups_list
          element :group_row
        end

        view 'app/assets/javascripts/members/components/table/role_dropdown.vue' do
          element :access_level_dropdown
          element :access_level_link
        end

        view 'app/assets/javascripts/members/components/action_dropdowns/user_action_dropdown.vue' do
          element :user_action_dropdown
        end

        view 'app/assets/javascripts/members/components/action_dropdowns/remove_member_dropdown_item.vue' do
          element :delete_member_dropdown_item
        end

        view 'app/assets/javascripts/members/components/action_buttons/approve_access_request_button.vue' do
          element :approve_access_request_button
        end

        view 'app/assets/javascripts/members/components/members_tabs.vue' do
          element :groups_list_tab
        end

        def update_access_level(username, access_level)
          search_member(username)

          within_element(:member_row, text: username) do
            click_element :access_level_dropdown
            click_element :access_level_link, text: access_level
          end
        end

        def remove_member(username)
          within_element(:member_row, text: username) do
            click_element :user_action_dropdown
            click_element :delete_member_dropdown_item
          end

          confirm_remove_member
        end

        def deny_access_request(username)
          within_element(:member_row, text: username) do
            click_element :delete_member_button
          end

          confirm_remove_member
        end

        def approve_access_request(username)
          within_element(:member_row, text: username) do
            click_element :approve_access_request_button
          end
        end

        def has_existing_group_share?(group_name)
          click_element :groups_list_tab

          within_element(:groups_list) do
            has_element?(:group_row, text: group_name)
          end
        end

        private

        def confirm_remove_member
          within_element(:remove_member_modal) do
            wait_for_enabled_remove_member_button

            click_element :remove_member_button
          end
        end

        def wait_for_enabled_remove_member_button
          retry_until(sleep_interval: 1, message: 'Waiting for remove member button to be enabled') do
            has_element?(:remove_member_button, disabled: false, wait: 3)
          end
        end
      end
    end
  end
end
