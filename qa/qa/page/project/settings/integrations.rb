# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Integrations < QA::Page::Base
          view 'app/assets/javascripts/integrations/index/components/integrations_table.vue' do
            element :prometheus_link, %q(:data-qa-selector="`${item.name}_link`") # rubocop:disable QA/ElementWithPattern
            element :jira_link, %q(:data-qa-selector="`${item.name}_link`") # rubocop:disable QA/ElementWithPattern
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

QA::Page::Project::Settings::Integrations.prepend_mod_with('Page::Project::Settings::Integrations', namespace: QA)
