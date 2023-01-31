# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Integrations < QA::Page::Base
          view 'app/assets/javascripts/integrations/index/components/integrations_table.vue' do
            element :jenkins_link, %q(:data-qa-selector="`${item.name}_link`") # rubocop:disable QA/ElementWithPattern
            element :prometheus_link, %q(:data-qa-selector="`${item.name}_link`") # rubocop:disable QA/ElementWithPattern
            element :jira_link, %q(:data-qa-selector="`${item.name}_link`") # rubocop:disable QA/ElementWithPattern
            element :pipelines_email_link, %q(:data-qa-selector="`${item.name}_link`") # rubocop:disable QA/ElementWithPattern
            element :gitlab_slack_application_link, %q(:data-qa-selector="`${item.name}_link`") # rubocop:disable QA/ElementWithPattern
          end

          def click_on_prometheus_integration
            click_element :prometheus_link
          end

          def click_pipelines_email_link
            click_element :pipelines_email_link
          end

          def click_jira_link
            click_element :jira_link
          end

          def click_jenkins_ci_link
            click_element :jenkins_link
          end

          def click_slack_application_link
            click_element :gitlab_slack_application_link
          end
        end
      end
    end
  end
end
