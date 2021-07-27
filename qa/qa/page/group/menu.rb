# frozen_string_literal: true

module QA
  module Page
    module Group
      class Menu < Page::Base
        include SubMenus::Common

        view 'app/views/layouts/nav/sidebar/_group_menus.html.haml' do
          element :general_settings_link
          element :group_settings
        end

        view 'app/views/groups/sidebar/_packages_settings.html.haml' do
          element :group_package_settings_link
        end

        view 'app/views/layouts/nav/sidebar/_analytics_links.html.haml' do
          element :analytics_link
          element :analytics_sidebar_submenu
        end

        def click_group_members_item
          hover_group_information do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Members')
            end
          end
        end

        def click_subgroup_members_item
          hover_subgroup_information do
            within_submenu do
              click_element(:sidebar_menu_item_link, menu_item: 'Members')
            end
          end
        end

        def click_settings
          within_sidebar do
            click_element(:group_settings)
          end
        end

        def click_contribution_analytics_item
          hover_element(:analytics_link) do
            within_submenu(:analytics_sidebar_submenu) do
              click_element(:contribution_analytics_link)
            end
          end
        end

        def click_group_general_settings_item
          hover_element(:group_settings) do
            within_submenu(:group_sidebar_submenu) do
              click_element(:general_settings_link)
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

        def go_to_package_settings
          scroll_to_element(:group_settings)
          hover_element(:group_settings) do
            within_submenu(:group_sidebar_submenu) do
              click_element(:group_package_settings_link)
            end
          end
        end

        private

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
      end
    end
  end
end

QA::Page::Group::Menu.prepend_mod_with('Page::Group::Menu', namespace: QA)
