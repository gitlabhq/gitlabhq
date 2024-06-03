# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        module Services
          class Slack < Page::Base
            view 'app/views/shared/integrations/gitlab_slack_application/_slack_integration_form.html.haml' do
              element 'install-slack-app-button'
            end

            def install_slack
              click_element('install-slack-app-button')
            end
          end
        end
      end
    end
  end
end
