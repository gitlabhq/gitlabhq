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
              element :confirm_user_button
            end

            def click_impersonate_user
              click_element(:impersonate_user_link)
            end

            def confirm_user
              accept_confirm do
                click_element :confirm_user_button
              end
            end
          end
        end
      end
    end
  end
end
