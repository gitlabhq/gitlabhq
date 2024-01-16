# frozen_string_literal: true

module QA
  module Page
    module User
      class Show < Page::Base
        view 'app/views/users/_follow_user.html.haml' do
          element 'follow-user-link'
        end

        view 'app/views/shared/users/_user.html.haml' do
          element 'user-link'
        end

        view 'app/views/users/_overview.html.haml' do
          element 'user-activity-content'
        end

        def click_follow_user_link
          click_element('follow-user-link')
        end

        def click_following_tab
          click_element('nav-item-link', submenu_item: 'Following')
        end

        def click_user_link(username)
          click_element('user-link', username: username)
        end

        def has_activity?(activity)
          within_element('user-activity-content') do
            has_text?(activity)
          end
        end
      end
    end
  end
end
