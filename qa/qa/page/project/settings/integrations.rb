# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Integrations < QA::Page::Base
          view 'app/views/shared/integrations/_index.html.haml' do
            element :prometheus_link, '{ data: { qa_selector: "#{integration.to_param' # rubocop:disable QA/ElementWithPattern
            element :jira_link, '{ data: { qa_selector: "#{integration.to_param' # rubocop:disable QA/ElementWithPattern
          end

          def click_on_prometheus_integration
            click_element :prometheus_link
          end

          def click_jira_link
            click_element :jira_link
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::Integrations.prepend_if_ee('QA::EE::Page::Project::Settings::Integrations')
