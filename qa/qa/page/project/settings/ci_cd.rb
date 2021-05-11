# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class CICD < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/projects/settings/ci_cd/show.html.haml' do
            element :autodevops_settings_content
            element :runners_settings_content
            element :variables_settings_content
            element :general_pipelines_settings_content
          end

          def expand_general_pipelines(&block)
            expand_content(:general_pipelines_settings_content) do
              Settings::GeneralPipelines.perform(&block)
            end
          end

          def expand_runners_settings(&block)
            expand_content(:runners_settings_content) do
              Settings::Runners.perform(&block)
            end
          end

          def expand_ci_variables(&block)
            expand_content(:variables_settings_content) do
              Settings::CiVariables.perform(&block)
            end
          end

          def expand_auto_devops(&block)
            expand_content(:autodevops_settings_content) do
              Settings::AutoDevops.perform(&block)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::CICD.prepend_mod_with("Page::Project::Settings::CICD", namespace: QA)
