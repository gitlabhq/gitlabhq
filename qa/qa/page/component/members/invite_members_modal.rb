# frozen_string_literal: true

module QA
  module Page
    module Component
      module Members
        module InviteMembersModal
          extend QA::Page::PageConcern
          include QA::Page::Component::Dropdown

          def self.included(base)
            super

            base.view 'app/assets/javascripts/invite_members/components/invite_modal_base.vue' do
              element 'invite-modal-submit'
              element 'access-level-dropdown'
              element 'invite-modal'
            end

            base.view 'app/assets/javascripts/invite_members/components/members_token_select.vue' do
              element 'members-token-select-input'
            end

            base.view 'app/assets/javascripts/invite_members/components/invite_group_trigger.vue' do
              element 'invite-group-button'
            end

            base.view 'app/assets/javascripts/invite_members/components/invite_members_trigger.vue' do
              element 'invite-members-button'
            end
          end

          def open_invite_members_modal
            dismiss_duo_chat_popup if respond_to?(:dismiss_duo_chat_popup)

            click_element 'invite-members-button'
          end

          def open_invite_group_modal
            click_element 'invite-group-button'
          end

          def add_member(username, access_level = 'Developer', refresh_page: true)
            open_invite_members_modal

            within_element('invite-modal') do
              fill_element('members-token-select-input', username)
              Support::WaitForRequests.wait_for_requests
              click_button(username, match: :prefer_exact)
              set_access_level(access_level)
            end

            send_invite(refresh_page)
          end

          def invite_group(group_name, access_level = 'Guest', refresh_page: true)
            open_invite_group_modal

            within_element('invite-modal') do
              click_button 'Select a group'

              Support::WaitForRequests.wait_for_requests

              search_and_select(group_name)

              set_access_level(access_level)
            end

            send_invite(refresh_page)
          end

          def send_invite(refresh = false)
            click_element 'invite-modal-submit'
            Support::WaitForRequests.wait_for_requests
            page.refresh if refresh
          end

          private

          def set_access_level(access_level)
            within_element('access-level-dropdown') do
              expand_select_list
              select_item access_level
            end
          end
        end
      end
    end
  end
end
