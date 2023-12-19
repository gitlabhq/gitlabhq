# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class CiCd < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/projects/settings/ci_cd/show.html.haml' do
            element 'autodevops-settings-content'
            element 'runners-settings-content'
            element 'variables-settings-content'
          end

          def expand_runners_settings(&block)
            expand_content('runners-settings-content') do
              Settings::Runners.perform(&block)
            end
          end

          def expand_ci_variables(&block)
            expand_content('variables-settings-content') do
              Settings::CiVariables.perform(&block)
            end
          end

          def expand_auto_devops(&block)
            expand_content('autodevops-settings-content') do
              Settings::AutoDevops.perform(&block)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::CiCd.prepend_mod_with("Page::Project::Settings::CiCd", namespace: QA)
