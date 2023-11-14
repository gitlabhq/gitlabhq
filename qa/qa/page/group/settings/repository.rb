# frozen_string_literal: true

module QA
  module Page
    module Group
      module Settings
        class Repository < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/shared/deploy_tokens/_index.html.haml' do
            element 'deploy-tokens-settings-content'
          end

          def expand_deploy_tokens(&block)
            expand_content('deploy-tokens-settings-content') do
              Settings::GroupDeployTokens.perform(&block)
            end
          end
        end
      end
    end
  end
end
