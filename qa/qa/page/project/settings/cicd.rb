module QA
  module Page
    module Project
      module Settings
        class CICD < Page::Base
          include Common

          view 'app/views/projects/settings/ci_cd/show.html.haml' do
            element :expand_secret_variables
          end

          def expand_secret_variables(&block)
            expand(:expand_secret_variables) do
              SecretVariables.perform(&block)
            end
          end
        end
      end
    end
  end
end
