# frozen_string_literal: true

module QA
  module Page
    module Component
      module InviteMembersModal
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/invite_members/components/invite_members_modal.vue' do
            element :invite_button
            element :access_level_dropdown
            element :invite_members_modal_content
          end

          base.view 'app/assets/javascripts/invite_members/components/group_select.vue' do
            element :group_select_dropdown_search_field
          end

          base.view 'app/assets/javascripts/invite_members/components/members_token_select.vue' do
            element :members_token_select_input
          end

          base.view 'app/assets/javascripts/invite_members/components/invite_group_trigger.vue' do
            element :invite_a_group_button
          end

          base.view 'app/assets/javascripts/invite_members/components/invite_members_trigger.vue' do
            element :invite_members_button
          end
        end

        def open_invite_members_modal
          click_element :invite_members_button
        end

        def open_invite_group_modal
          click_element :invite_a_group_button
        end

        def add_member(username, access_level = 'Developer')
          open_invite_members_modal

          within_element(:invite_members_modal_content) do
            fill_element :members_token_select_input, username
            Support::WaitForRequests.wait_for_requests
            click_button username

            # Guest option is selected by default, skipping these steps if desired option is 'Guest'
            unless access_level == 'Guest'
              click_element :access_level_dropdown
              click_button access_level
            end

            click_element :invite_button
          end

          Support::WaitForRequests.wait_for_requests

          page.refresh
        end

        def invite_group(group_name, group_access = Resource::Members::AccessLevel::GUEST)
          open_invite_group_modal

          fill_element :access_level_dropdown, with: group_access

          click_button 'Select a group'
          fill_element :group_select_dropdown_search_field, group_name

          Support::WaitForRequests.wait_for_requests

          click_button group_name

          click_element :invite_button

          Support::WaitForRequests.wait_for_requests

          page.refresh
        end
      end
    end
  end
end
