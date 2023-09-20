# frozen_string_literal: true

module QA
  module Page
    module Group
      class Menu < Page::Base
        include Page::SubMenus::Common
        include Page::SubMenus::Manage
        include Page::SubMenus::Plan
        include Page::SubMenus::Settings
        include SubMenus::Main
        include SubMenus::Build
        include SubMenus::Operate
        include SubMenus::Deploy
      end
    end
  end
end

QA::Page::Group::Menu.prepend_mod_with('Page::Group::Menu', namespace: QA)
