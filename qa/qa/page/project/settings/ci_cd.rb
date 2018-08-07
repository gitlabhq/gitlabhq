module QA # rubocop:disable Naming/FileName
  module Page
    module Project
      module Settings
        class CICD < Page::Base
          include Common

          view 'app/views/projects/settings/ci_cd/show.html.haml' do
            element :autodevops_settings
            element :runners_settings
            element :variables_settings
          end

          view 'app/views/projects/settings/ci_cd/_autodevops_form.html.haml' do
            element :enable_auto_devops_field, 'check_box :enabled'
            element :domain_field, 'text_field :domain'
            element :enable_auto_devops_button, "%strong= s_('CICD|Default to Auto DevOps pipeline')"
            element :domain_input, "%strong= _('Domain')"
            element :save_changes_button, "submit _('Save changes')"
          end

          def expand_runners_settings(&block)
            expand_section(:runners_settings) do
              Settings::Runners.perform(&block)
            end
          end

          def expand_secret_variables(&block)
            expand_section(:variables_settings) do
              Settings::SecretVariables.perform(&block)
            end
          end

          def enable_auto_devops_with_domain(domain)
            expand_section(:autodevops_settings) do
              check 'Default to Auto DevOps pipeline'
              fill_in 'Domain', with: domain
              click_on 'Save changes'
            end
          end
        end
      end
    end
  end
end
