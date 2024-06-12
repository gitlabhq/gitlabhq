# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class BranchRules < Page::Base
          view 'app/assets/javascripts/projects/settings/repository/branch_rules/components/branch_rule.vue' do
            element 'branch-content'
            element 'details-button'
          end

          def navigate_to_branch_rules_details(branch_name)
            within_element('branch-content', branch_name: branch_name) do
              click_element('details-button')
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::BranchRules.prepend_mod_with('Page::Project::Settings::BranchRules', namespace: QA)
