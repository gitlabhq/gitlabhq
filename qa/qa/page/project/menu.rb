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
        include SubMenus::Packages

        view 'app/views/layouts/nav/sidebar/_project.html.haml' do
          element :activity_link
          element :merge_requests_link
          element :snippets_link
          element :members_link
        end

        view 'app/views/layouts/nav/sidebar/_wiki_link.html.haml' do
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

        def click_snippets
          within_sidebar do
            click_element(:snippets_link)
          end
        end

        def click_members
          within_sidebar do
            click_element(:members_link)
          end
        end
      end
    end
  end
end

QA::Page::Project::Menu.prepend_if_ee('QA::EE::Page::Project::Menu')
