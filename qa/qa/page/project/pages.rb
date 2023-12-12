# frozen_string_literal: true

module QA
  module Page
    module Project
      class Pages < Page::Base
        view 'app/views/projects/pages/_access.html.haml' do
          element 'access-page-container'
        end

        def go_to_access_page
          within_element('access-page-container') do
            find('a').click
            page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
          end
        end
      end
    end
  end
end

QA::Page::Project::Pages.prepend_mod_with("Page::Project::Pages", namespace: QA)
