module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          include Common

          ##
          # TODO, define all selectors required by this page object
          #
          # See gitlab-org/gitlab-qa#154
          #
          view 'app/views/projects/settings/repository/show.html.haml'

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
