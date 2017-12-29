module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          def expand_deploy_keys(&block)
            expand('.qa-expand-deploy-keys') do
              DeployKeys.perform(&block)
            end
          end

          private

          def expand(selector)
            page.within('#content-body') do
              find(selector).click

              yield
            end
          end
        end
      end
    end
  end
end
