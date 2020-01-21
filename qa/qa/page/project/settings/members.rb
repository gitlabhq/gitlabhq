# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Members < Page::Base
          include Page::Component::UsersSelect
          include QA::Page::Component::Select2

          view 'app/views/shared/members/_invite_member.html.haml' do
            element :member_select_field
            element :invite_member_button
          end

          view 'app/views/projects/project_members/_team.html.haml' do
            element :members_list
          end

          view 'app/views/projects/project_members/index.html.haml' do
            element :invite_group_tab
          end

          view 'app/views/shared/members/_invite_group.html.haml' do
            element :group_select_field
            element :invite_group_button
          end

          view 'app/views/shared/members/_group.html.haml' do
            element :group_row
            element :delete_group_access_link
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

          def remove_group(group_name)
            click_element :invite_group_tab
            page.accept_alert do
              within_element(:group_row, text: group_name) do
                click_element :delete_group_access_link
              end
            end
          end
        end
      end
    end
  end
end
