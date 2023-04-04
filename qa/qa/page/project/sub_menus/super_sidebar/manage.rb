# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module Manage
            extend QA::Page::PageConcern

            def self.included(base)
              super

              base.class_eval do
                include QA::Page::Project::SubMenus::SuperSidebar::Common
              end
            end

            def go_to_activity
              open_manage_submenu('Activity')
            end

            def go_to_members
              open_manage_submenu('Members')
            end

            def go_to_labels
              open_manage_submenu('Labels')
            end

            def go_to_milestones
              open_manage_submenu('Milestones')
            end

            private

            def open_manage_submenu(sub_menu)
              open_submenu('Manage', '#manage', sub_menu)
            end
          end
        end
      end
    end
  end
end
