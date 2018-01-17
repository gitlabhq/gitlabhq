module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          include Common

          view 'app/views/projects/deploy_keys/_index.html.haml' do
            element :expand_deploy_keys
          end

          def expand_deploy_keys(&block)
            expand(:expand_deploy_keys) do
              DeployKeys.perform(&block)
            end
          end
        end
      end
    end
  end
end
