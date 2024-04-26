# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Integrations < QA::Page::Base
          # rubocop:disable QA/ElementWithPattern -- required for qa:selectors job to pass
          view 'app/assets/javascripts/integrations/index/components/integrations_table.vue' do
            element 'jenkins-link', %q(:data-testid="`${item.name}-link`")
            element 'prometheus-link', %q(:data-testid="`${item.name}-link`")
            element 'jira-link', %q(:data-testid="`${item.name}-link`")
            element 'pipelines_email-link', %q(:data-testid="`${item.name}-link`")
            element 'gitlab_slack_application-link', %q(:data-testid="`${item.name}-link`")
            element 'google_cloud_platform_workload_identity_federation-link', %q(:data-testid="`${item.name}-link`")
            element 'google_cloud_platform_artifact_registry-link', %q(:data-testid="`${item.name}-link`")
          end
          # rubocop:enable QA/ElementWithPattern

          def click_on_prometheus_integration
            click_element('prometheus-link')
          end

          def click_pipelines_email_link
            click_element('pipelines_email-link')
          end

          def click_jira_link
            click_element('jira-link')
          end

          def click_jenkins_ci_link
            click_element('jenkins-link')
          end

          def click_slack_application_link
            click_element('gitlab_slack_application-link')
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::Integrations.prepend_mod_with("Page::Project::Settings::Integrations", namespace: QA)
