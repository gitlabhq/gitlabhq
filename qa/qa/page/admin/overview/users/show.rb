# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Users
          class Show < QA::Page::Base
            view 'app/views/admin/users/_head.html.haml' do
              element :impersonate_user_link
            end

            view 'app/views/admin/users/show.html.haml' do
              element :user_id_content
            end

            view 'app/assets/javascripts/admin/users/components/actions/approve.vue' do
              element :approve_user_button
              element :approve_user_confirm_button
            end

            view 'app/assets/javascripts/admin/users/components/user_actions.vue' do
              element :user_actions_dropdown_toggle
            end

            view 'app/helpers/users_helper.rb' do
              element :confirm_user_button
              element :confirm_user_confirm_button
            end

            def open_user_actions_dropdown(user)
              click_element(:user_actions_dropdown_toggle, username: user.username)
            end

            def click_impersonate_user
              click_element(:impersonate_user_link)
            end

            def user_id
              find_element(:user_id_content).text
            end

            def confirm_user
              click_element :confirm_user_button
              click_element :confirm_user_confirm_button
            end

            def approve_user(user)
              open_user_actions_dropdown(user)
              click_element :approve_user_button
              click_element :approve_user_confirm_button
            end
          end
        end
      end
    end
  end
end
