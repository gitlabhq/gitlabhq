# frozen_string_literal: true

module QA
  module Page
    module Project
      class Members < Page::Base
        include QA::Page::Component::InviteMembersModal

        view 'app/assets/javascripts/members/components/members_tabs.vue' do
          element :groups_list_tab
        end

        view 'app/assets/javascripts/invite_members/components/invite_group_trigger.vue' do
          element :invite_a_group_button
        end

        view 'app/assets/javascripts/invite_members/components/invite_members_trigger.vue' do
          element :invite_members_button
        end

        view 'app/assets/javascripts/pages/projects/project_members/index.js' do
          element :group_row
        end

        view 'app/assets/javascripts/members/components/action_buttons/remove_group_link_button.vue' do
          element :delete_group_access_link
        end

        view 'app/assets/javascripts/members/components/modals/remove_group_link_modal.vue' do
          element :remove_group_link_modal_content
        end

        def remove_group(group_name)
          click_element :groups_list_tab

          within_element(:group_row, text: group_name) do
            click_element :delete_group_access_link
          end

          within_element(:remove_group_link_modal_content) do
            click_button 'Remove group'
          end
        end
      end
    end
  end
end
