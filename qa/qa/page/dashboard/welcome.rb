# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Welcome < Page::Base
        # Old flow: /dashboard/projects with zero authorized projects
        view 'app/views/dashboard/projects/_zero_authorized_projects.html.haml' do
          element 'welcome-title-content'
        end

        # New flow: /dashboard/homepage (Vue app)
        view 'app/assets/javascripts/homepage/components/greeting_header.vue' do
          element 'homepage-greeting-header'
        end

        def has_welcome_title?(admin = false)
          # Support both old and new homepage flows
          # Old flow: admin users see "Welcome to GitLab" in the zero-projects state
          # New flow: non-admin users see the greeting header with a rotating greeting message
          if admin
            has_element?('welcome-title-content', text: "Welcome to GitLab")
          else
            has_element?('homepage-greeting-header') && has_element?('greeting-message')
          end
        end

        def self.path
          '/'
        end
      end
    end
  end
end
