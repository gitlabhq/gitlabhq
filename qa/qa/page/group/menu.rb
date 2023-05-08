# frozen_string_literal: true

module QA
  module Page
    module Group
      class Menu < Page::Base
        include SubMenus::Common

        if Runtime::Env.super_sidebar_enabled?
          prepend Page::SubMenus::SuperSidebar::Manage
          prepend Page::SubMenus::SuperSidebar::Plan
          prepend Page::SubMenus::SuperSidebar::Settings
          prepend SubMenus::SuperSidebar::Main
          prepend SubMenus::SuperSidebar::Build
          prepend SubMenus::SuperSidebar::Operate
        end

        def click_group_members_item
          hover_group_information do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Members')
            end
          end
        end

        def click_subgroup_members_item
          return go_to_members if Runtime::Env.super_sidebar_enabled?

          hover_subgroup_information do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Members')
            end
          end
        end

        def click_settings
          within_sidebar do
            click_element(:sidebar_menu_link, menu_item: 'Settings')
          end
        end

        def click_group_general_settings_item
          return go_to_general_settings if Runtime::Env.super_sidebar_enabled?

          hover_group_settings do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'General')
            end
          end
        end

        def go_to_milestones
          hover_issues do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Milestones')
            end
          end
        end

        def go_to_runners
          hover_group_ci_cd do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Runners')
            end
          end
        end

        def go_to_package_settings
          hover_group_settings do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Packages and registries')
            end
          end
        end

        def go_to_group_packages
          return go_to_package_registry if Runtime::Env.super_sidebar_enabled?

          hover_group_packages do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Package Registry')
            end
          end
        end

        def go_to_dependency_proxy
          hover_group_packages do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Dependency Proxy')
            end
          end
        end

        def go_to_repository_settings
          hover_group_settings do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Repository')
            end
          end
        end

        def go_to_access_token_settings
          hover_group_settings do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Access Tokens')
            end
          end
        end

        def go_to_workspaces
          within_sidebar do
            click_element(:sidebar_menu_link, menu_item: "Workspaces")
          end
        end

        private

        def hover_settings
          within_sidebar do
            scroll_to_element(:sidebar_menu_link, menu_item: 'Settings')
            find_element(:sidebar_menu_link, menu_item: 'Settings').hover

            yield
          end
        end

        def hover_issues
          within_sidebar do
            scroll_to_element(:sidebar_menu_link, menu_item: 'Issues')
            find_element(:sidebar_menu_link, menu_item: 'Issues').hover

            yield
          end
        end

        def hover_group_information
          within_sidebar do
            find_element(:sidebar_menu_link, menu_item: 'Group information').hover

            yield
          end
        end

        def hover_subgroup_information
          within_sidebar do
            find_element(:sidebar_menu_link, menu_item: 'Subgroup information').hover

            yield
          end
        end

        def hover_group_ci_cd
          within_sidebar do
            find_element(:sidebar_menu_link, menu_item: 'CI/CD').hover

            yield
          end
        end

        def hover_group_packages
          within_sidebar do
            scroll_to_element(:sidebar_menu_link, menu_item: 'Packages and registries')
            find_element(:sidebar_menu_link, menu_item: 'Packages and registries').hover

            yield
          end
        end

        def hover_group_settings
          within_sidebar do
            scroll_to_element(:sidebar_menu_link, menu_item: 'Settings')
            find_element(:sidebar_menu_link, menu_item: 'Settings').hover

            yield
          end
        end
      end
    end
  end
end

QA::Page::Group::Menu.prepend_mod_with('Page::Group::Menu', namespace: QA)
