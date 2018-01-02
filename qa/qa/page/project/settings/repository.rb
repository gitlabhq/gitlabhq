module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          include Common

          def expand_deploy_keys(&block)
            expand('.qa-expand-deploy-keys') do
              DeployKeys.perform(&block)
            end
          end
        end
      end
    end
  end
end
