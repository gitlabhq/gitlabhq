# frozen_string_literal: true

module QA
  module Page
    module Project
      class Menu < Page::Base
        include SubMenus::Common
        include SubMenus::Project
        include SubMenus::CiCd
        include SubMenus::Issues
        include SubMenus::Deployments
        include SubMenus::Monitor
        include SubMenus::Infrastructure
        include SubMenus::Repository
        include SubMenus::Settings
        include SubMenus::Packages
        include SubMenus::CreateNewMenu

        if Runtime::Env.super_sidebar_enabled?
          include Page::SubMenus::SuperSidebar::Manage
          include SubMenus::SuperSidebar::Plan
          include SubMenus::SuperSidebar::Settings
          include SubMenus::SuperSidebar::Code
          include SubMenus::SuperSidebar::Build
          include SubMenus::SuperSidebar::Operate
          include SubMenus::SuperSidebar::Monitor
          include SubMenus::SuperSidebar::Main
        end

        def click_merge_requests
          return go_to_merge_requests if Runtime::Env.super_sidebar_enabled?

          within_sidebar do
            click_element(:sidebar_menu_link, menu_item: 'Merge requests')
          end
        end

        def click_wiki
          return go_to_wiki if Runtime::Env.super_sidebar_enabled?

          within_sidebar do
            click_element(:sidebar_menu_link, menu_item: 'Wiki')
          end
        end

        def click_activity
          return go_to_activity if Runtime::Env.super_sidebar_enabled?

          hover_project_information do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Activity')
            end
          end
        end

        def click_snippets
          return go_to_snippets if Runtime::Env.super_sidebar_enabled?

          within_sidebar do
            click_element(:sidebar_menu_link, menu_item: 'Snippets')
          end
        end

        def click_members
          return go_to_members if Runtime::Env.super_sidebar_enabled?

          hover_project_information do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Members')
            end
          end
        end

        private

        def hover_project_information
          within_sidebar do
            scroll_to_element(:sidebar_menu_link, menu_item: 'Project information')
            find_element(:sidebar_menu_link, menu_item: 'Project information').hover

            yield
          end
        end
      end
    end
  end
end

QA::Page::Project::Menu.prepend_mod_with('Page::Project::Menu', namespace: QA)
