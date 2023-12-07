# frozen_string_literal: true

module QA
  module Page
    module Project
      class Menu < Page::Base
        include SubMenus::CreateNewMenu
        include SubMenus::Plan
        include SubMenus::Settings
        include SubMenus::Code
        include SubMenus::Build
        include SubMenus::Operate
        include SubMenus::Monitor
        include SubMenus::Main
        include Page::SubMenus::Manage
        include Page::SubMenus::Deploy
      end
    end
  end
end

QA::Page::Project::Menu.prepend_mod_with('Page::Project::Menu', namespace: QA)
