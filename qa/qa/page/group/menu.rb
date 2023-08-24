# frozen_string_literal: true

module QA
  module Page
    module Group
      class Menu < Page::Base
        include QA::Page::SubMenus::Common
        include Page::SubMenus::SuperSidebar::Manage
        include Page::SubMenus::SuperSidebar::Plan
        include Page::SubMenus::SuperSidebar::Settings
        include SubMenus::SuperSidebar::Main
        include SubMenus::SuperSidebar::Build
        include SubMenus::SuperSidebar::Operate
        include SubMenus::SuperSidebar::Deploy
      end
    end
  end
end

QA::Page::Group::Menu.prepend_mod_with('Page::Group::Menu', namespace: QA)
