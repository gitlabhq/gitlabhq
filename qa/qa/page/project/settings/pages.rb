# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Pages < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/projects/pages/_access.html.haml' do
            element :access_page_container
          end

          def go_to_access_page
            within_element(:access_page_container) do
              find('a').click
              page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::Pages.prepend_mod_with("Page::Project::Settings::Pages", namespace: QA)
