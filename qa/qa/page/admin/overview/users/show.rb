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

            view 'app/views/admin/users/_approve_user.html.haml' do
              element :approve_user_button
            end

            view 'app/helpers/users_helper.rb' do
              element :confirm_user_button
              element :confirm_user_confirm_button
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

            def approve_user
              accept_confirm do
                click_element :approve_user_button
              end
            end
          end
        end
      end
    end
  end
end
