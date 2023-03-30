# frozen_string_literal: true

module QA
  module Page
    module Group
      module SubMenus
        module SuperSidebar
          module Settings
            extend QA::Page::PageConcern

            def self.included(base)
              super

              base.class_eval do
                include Common
              end
            end

            def go_to_general_settings
              open_settings_submenu("General")
            end

            private

            def open_settings_submenu(sub_menu)
              open_submenu("Settings", "#settings", sub_menu)
            end
          end
        end
      end
    end
  end
end
