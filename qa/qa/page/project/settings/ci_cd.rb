# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class CICD < Page::Base
          include Common

          view 'app/views/projects/settings/ci_cd/show.html.haml' do
            element :autodevops_settings_content
            element :runners_settings_content
            element :variables_settings_content
          end

          view 'app/views/projects/settings/ci_cd/_autodevops_form.html.haml' do
            element :enable_autodevops_checkbox
            element :save_changes_button
          end

          def expand_runners_settings(&block)
            expand_section(:runners_settings_content) do
              Settings::Runners.perform(&block)
            end
          end

          def expand_ci_variables(&block)
            expand_section(:variables_settings_content) do
              Settings::CiVariables.perform(&block)
            end
          end

          def enable_auto_devops
            expand_section(:autodevops_settings_content) do
              check_element :enable_autodevops_checkbox
              click_element :save_changes_button
            end
          end
        end
      end
    end
  end
end
