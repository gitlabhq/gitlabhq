# frozen_string_literal: true

module QA
  module Page
    module Group
      class Menu < Page::Base
        include SubMenus::Common

        view 'app/views/layouts/nav/sidebar/_group.html.haml' do
          element :group_settings_item
          element :group_members_item
          element :general_settings_link
          element :contribution_analytics_link
        end

        def click_group_members_item
          within_sidebar do
            click_element(:group_members_item)
          end
        end

        def click_group_analytics_item
          within_sidebar do
            click_element(:contribution_analytics_link)
          end
        end

        def click_group_general_settings_item
          hover_element(:group_settings_item) do
            within_submenu(:group_sidebar_submenu) do
              click_element(:general_settings_link)
            end
          end
        end
      end
    end
  end
end

QA::Page::Group::Menu.prepend_if_ee('QA::EE::Page::Group::Menu')
