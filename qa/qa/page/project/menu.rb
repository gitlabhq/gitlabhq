# frozen_string_literal: true

module QA
  module Page
    module Project
      class Menu < Page::Base
        include SubMenus::Common
        include SubMenus::CreateNewMenu
        include SubMenus::SuperSidebar::Plan
        include SubMenus::SuperSidebar::Settings
        include SubMenus::SuperSidebar::Code
        include SubMenus::SuperSidebar::Build
        include SubMenus::SuperSidebar::Operate
        include SubMenus::SuperSidebar::Monitor
        include SubMenus::SuperSidebar::Main
        include Page::SubMenus::SuperSidebar::Manage
        include Page::SubMenus::SuperSidebar::Deploy
      end
    end
  end
end

QA::Page::Project::Menu.prepend_mod_with('Page::Project::Menu', namespace: QA)
