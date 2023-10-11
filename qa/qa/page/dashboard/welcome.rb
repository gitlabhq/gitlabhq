# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Welcome < Page::Base
        view 'app/views/dashboard/projects/_zero_authorized_projects.html.haml' do
          element 'welcome-title-content'
        end

        def has_welcome_title?(text)
          has_element?('welcome-title-content', text: text)
        end

        def self.path
          '/'
        end
      end
    end
  end
end
