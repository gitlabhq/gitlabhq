module QA # rubocop:disable Naming/FileName
  module Page
    module Project
      module Settings
        class CICD < Page::Base
          include Common

          view 'app/views/projects/settings/ci_cd/show.html.haml' do
            element :runners_settings, 'Runners settings'
            element :secret_variables, 'Variables'
            element :auto_devops_section, 'Auto DevOps'
          end

          view 'app/views/projects/settings/ci_cd/_autodevops_form.html.haml' do
            element :enable_auto_devops_button, 'Enable Auto DevOps'
            element :domain_input, 'Domain'
            element :save_changes_button, "submit 'Save changes'"
          end

          def expand_runners_settings(&block)
            expand_section('Runners settings') do
              Settings::Runners.perform(&block)
            end
          end

          def expand_secret_variables(&block)
            expand_section('Variables') do
              Settings::SecretVariables.perform(&block)
            end
          end

          def enable_auto_devops_with_domain(domain)
            expand_section('Auto DevOps') do
              choose 'Enable Auto DevOps'
              fill_in 'Domain', with: domain
              click_on 'Save changes'
            end
          end
        end
      end
    end
  end
end
