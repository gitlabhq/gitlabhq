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

        def click_merge_requests
          within_sidebar do
            click_element(:sidebar_menu_link, menu_item: 'Merge requests')
          end
        end

        def click_wiki
          within_sidebar do
            click_element(:sidebar_menu_link, menu_item: 'Wiki')
          end
        end

        def click_activity
          within_sidebar do
            click_element(:sidebar_menu_item_link, menu_item: 'Activity')
          end
        end

        def click_snippets
          within_sidebar do
            click_element(:sidebar_menu_link, menu_item: 'Snippets')
          end
        end

        def click_members
          within_sidebar do
            click_element(:sidebar_menu_link, menu_item: 'Members')
          end
        end
      end
    end
  end
end

QA::Page::Project::Menu.prepend_mod_with('Page::Project::Menu', namespace: QA)
