# frozen_string_literal: true

module QA
  module Page
    module Component
      module Members
        module MembersTable
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include MembersFilter
              include RemoveMemberModal
              include RemoveGroupModal
            end

            base.view 'app/assets/javascripts/members/components/table/members_table.vue' do
              element :member_row
            end

            base.view 'app/assets/javascripts/members/components/table/role_dropdown.vue' do
              element :access_level_dropdown
              element :access_level_link
            end

            base.view 'app/assets/javascripts/members/components/action_dropdowns/user_action_dropdown.vue' do
              element :user_action_dropdown
            end

            base.view 'app/assets/javascripts/members/components/action_dropdowns/remove_member_dropdown_item.vue' do
              element :delete_member_dropdown_item
            end

            base.view 'app/assets/javascripts/members/components/action_buttons/approve_access_request_button.vue' do
              element :approve_access_request_button
            end

            base.view 'app/assets/javascripts/members/components/members_tabs.vue' do
              element :groups_list_tab
            end

            base.view 'app/assets/javascripts/members/components/action_buttons/remove_group_link_button.vue' do
              element :remove_group_link_button
            end
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

          def approve_access_request(username)
            within_element(:member_row, text: username) do
              click_element :approve_access_request_button
            end
          end

          def deny_access_request(username)
            within_element(:member_row, text: username) do
              click_element :delete_member_button
            end

            confirm_remove_member
          end

          def remove_group(group_name)
            click_element :groups_list_tab

            within_element(:member_row, text: group_name) do
              click_element :remove_group_link_button
            end

            confirm_remove_group
          end

          def has_group?(group_name)
            click_element :groups_list_tab
            has_element?(:member_row, text: group_name)
          end
        end
      end
    end
  end
end
