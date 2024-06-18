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
              include ConfirmModal
            end

            base.view 'app/assets/javascripts/members/components/table/members_table.vue' do
              element 'members-table'
            end

            base.view 'app/assets/javascripts/members/components/table/max_role.vue' do
              element 'access-level-dropdown'
              element 'access-level-link'
            end

            base.view 'app/assets/javascripts/members/components/action_dropdowns/user_action_dropdown.vue' do
              element 'user-action-dropdown'
            end

            base.view 'app/assets/javascripts/members/components/action_dropdowns/remove_member_dropdown_item.vue' do
              element 'delete-member-dropdown-item'
            end

            base.view 'app/assets/javascripts/members/components/action_buttons/approve_access_request_button.vue' do
              element 'approve-access-request-button'
            end

            base.view 'app/assets/javascripts/members/tabs_metadata.js' do
              element 'groups-list-tab'
            end

            base.view 'app/assets/javascripts/members/components/action_buttons/remove_group_link_button.vue' do
              element('remove-group-link-button')
            end
          end

          def update_access_level(username, access_level)
            search_member(username)

            within_element('members-table', text: username) do
              click_element('access-level-dropdown')
              click_element('access-level-link', text: access_level)
            end

            click_confirmation_ok_button_if_present
          end

          def remove_member(username)
            within_element('members-table', text: username) do
              click_element 'user-action-dropdown'
              click_element 'delete-member-dropdown-item'
            end

            confirm_remove_member
          end

          def approve_access_request(username)
            within_element('members-table', text: username) do
              click_element 'approve-access-request-button'
            end
          end

          def deny_access_request(username)
            within_element('members-table', text: username) do
              click_element 'delete-member-button'
            end

            confirm_remove_member
          end

          def remove_group(group_name)
            click_element 'groups-list-tab'

            within_element('members-table', text: group_name) do
              click_element('remove-group-link-button')
            end

            confirm_remove_group
          end

          def has_group?(group_name)
            click_element 'groups-list-tab'
            has_element?('members-table', text: group_name)
          end
        end
      end
    end
  end
end
