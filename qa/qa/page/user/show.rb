# frozen_string_literal: true

module QA
  module Page
    module User
      class Show < Page::Base
        view 'app/views/users/show.html.haml' do
          element :follow_user_link
          element :following_link
        end

        view 'app/views/shared/users/_user.html.haml' do
          element :user_link
        end

        view 'app/views/users/_overview.html.haml' do
          element :user_activity_content
        end

        def click_follow_user_link
          click_element(:follow_user_link)
        end

        def click_following_link
          click_element(:following_link)
        end

        def click_user_link(username)
          click_element(:user_link, username: username)
        end

        def has_activity?(activity)
          within_element(:user_activity_content) do
            has_text?(activity)
          end
        end
      end
    end
  end
end
