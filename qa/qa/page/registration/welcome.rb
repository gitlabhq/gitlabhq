# frozen_string_literal: true

module QA
  module Page
    module Registration
      class Welcome < Page::Base
        view 'ee/app/views/registrations/welcome/show.html.haml' do
          element :get_started_button
          element :role_dropdown
        end

        view 'ee/app/views/registrations/welcome/_setup_for_company.html.haml' do
          element :setup_for_just_me_content
          element :setup_for_just_me_radio
        end

        view 'ee/app/views/registrations/welcome/_joining_project.html.haml' do
          element :create_a_new_project_radio
        end

        def has_get_started_button?(wait: Capybara.default_max_wait_time)
          has_element?(:get_started_button, wait: wait)
        end

        def select_role(role)
          select_element(:role_dropdown, role)
        end

        def choose_create_a_new_project_if_available
          click_element(:create_a_new_project_radio) if has_element?(:create_a_new_project_radio, wait: 1)
        end

        def choose_setup_for_just_me_if_available
          choose_element(:setup_for_just_me_radio, true) if has_element?(:setup_for_just_me_content, wait: 1)
        end

        def click_get_started_button
          Support::Retrier.retry_until do
            click_element :get_started_button
            has_no_element?(:get_started_button)
          end
        end
      end
    end
  end
end
