# frozen_string_literal: true

module QA
  module Page
    module Project
      module Operations
        class Metrics < Page::Base
          EXPECTED_TITLE = 'Memory Usage (Total)'
          LOADING_MESSAGE = 'Waiting for performance data'

          view 'app/assets/javascripts/monitoring/components/dashboard.vue' do
            element :prometheus_graphs
          end

          view 'app/assets/javascripts/monitoring/components/charts/time_series.vue' do
            element :prometheus_graph_widgets
          end

          view 'app/assets/javascripts/monitoring/components/panel_type.vue' do
            element :prometheus_widgets_dropdown
            element :alert_widget_menu_item
          end

          def wait_for_metrics
            wait_for_data
            return if has_metrics?

            wait_until(max_duration: 180) do
              wait_for_data
              has_metrics?
            end
          end

          def wait_for_data
            wait_until(reload: false) { !has_text?(LOADING_MESSAGE) } if has_text?(LOADING_MESSAGE)
          end

          def has_metrics?
            within_element :prometheus_graphs do
              has_text?(EXPECTED_TITLE)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Operations::Metrics.prepend_if_ee('QA::EE::Page::Project::Operations::Metrics')
