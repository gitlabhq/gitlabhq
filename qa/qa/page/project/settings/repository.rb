module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          include Common

          view 'app/views/projects/deploy_keys/_index.html.haml' do
            element :deploy_keys_section, 'Deploy Keys'
          end

          def expand_deploy_keys(&block)
            expand_section('Deploy Keys') do
              DeployKeys.perform(&block)
            end
          end
        end
      end
    end
  end
end
