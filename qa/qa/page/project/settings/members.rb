# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Members < Page::Base
          include Page::Component::UsersSelect

          view 'app/views/projects/project_members/_new_project_member.html.haml' do
            element :member_select_input
            element :add_member_button
          end

          view 'app/views/projects/project_members/_team.html.haml' do
            element :members_list
          end

          def add_member(username)
            select_user :member_select_input, username
            click_element :add_member_button
          end
        end
      end
    end
  end
end
