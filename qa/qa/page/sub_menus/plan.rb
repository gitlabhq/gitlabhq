# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module Plan
        extend QA::Page::PageConcern

        def go_to_issue_boards
          open_plan_submenu("Issue boards")
        end

        def go_to_service_desk
          open_plan_submenu("Service Desk")
        end

        def go_to_wiki
          open_plan_submenu("Wiki")
        end

        def go_to_milestones
          open_plan_submenu('Milestones')
        end

        private

        def open_plan_submenu(sub_menu)
          open_submenu("Plan", sub_menu)
        end
      end
    end
  end
end
