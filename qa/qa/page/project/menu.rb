# frozen_string_literal: true

module QA
  module Page
    module Project
      class Menu < Page::Base
        include SubMenus::Common
        include SubMenus::Project
        include SubMenus::CiCd
        include SubMenus::Issues
        include SubMenus::Operations
        include SubMenus::Repository
        include SubMenus::Settings

        view 'app/views/layouts/nav/sidebar/_project.html.haml' do
          element :activity_link
          element :merge_requests_link
          element :wiki_link
        end

        def click_merge_requests
          within_sidebar do
            click_element(:merge_requests_link)
          end
        end

        def click_wiki
          within_sidebar do
            click_element(:wiki_link)
          end
        end

        def click_activity
          within_sidebar do
            click_element(:activity_link)
          end
        end
      end
    end
  end
end
