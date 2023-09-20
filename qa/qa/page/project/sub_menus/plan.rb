# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Plan
          def self.included(base)
            super

            base.class_eval do
              include QA::Page::SubMenus::Plan
            end
          end

          def go_to_requirements
            open_plan_submenu("Requirements")
          end

          def go_to_jira_issues
            open_plan_submenu("Jira issues")
          end

          def go_to_open_jira
            open_plan_submenu("Open Jira")
          end

          def go_to_issues
            open_plan_submenu("Issues")
          end
        end
      end
    end
  end
end
