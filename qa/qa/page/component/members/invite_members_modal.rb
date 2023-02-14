# frozen_string_literal: true

module QA
  module Page
    module Component
      module Members
        module InviteMembersModal
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/invite_members/components/invite_modal_base.vue' do
              element :invite_button
              element :access_level_dropdown
              element :invite_members_modal_content
            end

            base.view 'app/assets/javascripts/invite_members/components/group_select.vue' do
              element :group_select_dropdown_search_field
              element :group_select_dropdown_item
            end

            base.view 'app/assets/javascripts/invite_members/components/members_token_select.vue' do
              element :members_token_select_input
            end

            base.view 'app/assets/javascripts/invite_members/components/invite_group_trigger.vue' do
              element :invite_a_group_button
            end

            base.view 'app/assets/javascripts/invite_members/constants.js' do
              element :invite_members_button
            end
          end

          def open_invite_members_modal
            click_element :invite_members_button
          end

          def open_invite_group_modal
            click_element :invite_a_group_button
          end

          def add_member(username, access_level = 'Developer', refresh_page: true)
            open_invite_members_modal

            within_element(:invite_members_modal_content) do
              fill_element(:members_token_select_input, username)
              Support::WaitForRequests.wait_for_requests
              click_button(username, match: :prefer_exact)
              set_access_level(access_level)
            end

            send_invite(refresh_page)
          end

          def invite_group(group_name, access_level = 'Guest', refresh_page: true)
            open_invite_group_modal

            within_element(:invite_members_modal_content) do
              click_button 'Select a group'

              Support::Waiter.wait_until { has_element?(:group_select_dropdown_item) }

              fill_element :group_select_dropdown_search_field, group_name
              Support::WaitForRequests.wait_for_requests
              click_button group_name

              set_access_level(access_level)
            end

            send_invite(refresh_page)
          end

          def send_invite(refresh = false)
            click_element :invite_button
            Support::WaitForRequests.wait_for_requests
            page.refresh if refresh
          end

          private

          def set_access_level(access_level)
            # Guest option is selected by default, skipping these steps if desired option is 'Guest'
            select_element(:access_level_dropdown, access_level) unless access_level == 'Guest'
          end
        end
      end
    end
  end
end
