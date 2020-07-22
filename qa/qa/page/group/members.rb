# frozen_string_literal: true

module QA
  module Page
    module Group
      class Members < Page::Base
        include QA::Page::Component::Select2
        include Page::Component::UsersSelect

        view 'app/assets/javascripts/vue_shared/components/remove_member_modal.vue' do
          element :remove_member_modal_content
        end

        view 'app/views/shared/members/_invite_member.html.haml' do
          element :member_select_field
          element :invite_member_button
        end

        view 'app/views/shared/members/_member.html.haml' do
          element :member_row
          element :access_level_dropdown
          element :delete_member_button
          element :developer_access_level_link, 'qa_selector: "#{role.downcase}_access_level_link"' # rubocop:disable QA/ElementWithPattern, Lint/InterpolationCheck
        end

        view 'app/views/groups/group_members/index.html.haml' do
          element :invite_group_tab
          element :groups_list
        end

        view 'app/views/shared/members/_invite_group.html.haml' do
          element :group_select_field
          element :invite_group_button
        end

        view 'app/views/shared/members/_group.html.haml' do
          element :group_row
        end

        def select_group(group_name)
          click_element :group_select_field
          search_and_select(group_name)
        end

        def invite_group(group_name)
          click_element :invite_group_tab
          select_group(group_name)
          click_element :invite_group_button
        end

        def add_member(username)
          select_user :member_select_field, username
          click_element :invite_member_button
        end

        def update_access_level(username, access_level)
          within_element(:member_row, text: username) do
            click_element :access_level_dropdown
            click_element "#{access_level.downcase}_access_level_link"
          end
        end

        def remove_member(username)
          within_element(:member_row, text: username) do
            click_element :delete_member_button
          end

          within_element(:remove_member_modal_content) do
            click_button("Remove member")
          end
        end

        def has_existing_group_share?(group_name)
          within_element(:groups_list) do
            has_element?(:group_row, text: group_name)
          end
        end
      end
    end
  end
end
