# frozen_string_literal: true

module QA
  module Page
    module Group
      module SubMenus
        class Members < Page::Base
          include Page::Component::UsersSelect

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
            page.accept_confirm do
              within_element(:member_row, text: username) do
                click_element :delete_member_button
              end
            end
          end
        end
      end
    end
  end
end
