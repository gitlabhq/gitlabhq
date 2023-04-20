# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class BranchRulesDetails < Page::Base
          view 'app/assets/javascripts/projects/settings/branch_rules/components/view/index.vue' do
            element :allowed_to_push_content
            element :allowed_to_merge_content
          end

          view 'app/assets/javascripts/projects/settings/branch_rules/components/view/protection_row.vue' do
            element :access_level_content
          end

          def has_allowed_to_push?(role)
            within_element(:allowed_to_push_content) do
              has_element?(:access_level_content, role: role)
            end
          end

          def has_allowed_to_merge?(role)
            within_element(:allowed_to_merge_content) do
              has_element?(:access_level_content, role: role)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::BranchRulesDetails.prepend_mod_with( # rubocop:disable Cop/InjectEnterpriseEditionModule
  'Page::Project::Settings::BranchRulesDetails', namespace: QA)
