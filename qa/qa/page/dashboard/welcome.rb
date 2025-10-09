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

        def has_welcome_title?(text)
          # Support both old and new homepage flows
          # Old flow checks for specific text (e.g., "Welcome to GitLab")
          # New flow checks for the greeting header element and "Today's highlights"
          has_element?('welcome-title-content', text: text) ||
            (has_element?('homepage-greeting-header') && has_text?(text))
        end

        def self.path
          '/'
        end
      end
    end
  end
end
