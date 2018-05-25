module QA # rubocop:disable Naming/FileName
  module Page
    module Project
      module Settings
        class CICD < Page::Base
          include Common

          view 'app/views/projects/settings/ci_cd/show.html.haml' do
            element :runners_settings, 'Runners settings'
            element :secret_variables, 'Variables'
            element :auto_devops, 'Auto DevOps (Beta)'
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
