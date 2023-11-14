# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class BranchRulesDetails < Page::Base
          view 'app/assets/javascripts/projects/settings/branch_rules/components/view/index.vue' do
            element 'allowed-to-push-content'
            element 'allowed-to-merge-content'
          end

          view 'app/assets/javascripts/projects/settings/branch_rules/components/view/protection_row.vue' do
            element 'access-level'
          end

          def has_allowed_to_push?(role)
            within_element('allowed-to-push-content') do
              has_element?('access-level', role: role)
            end
          end

          def has_allowed_to_merge?(role)
            within_element('allowed-to-merge-content') do
              has_element?('access-level', role: role)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::BranchRulesDetails.prepend_mod_with( # rubocop:disable Cop/InjectEnterpriseEditionModule
  'Page::Project::Settings::BranchRulesDetails', namespace: QA)
