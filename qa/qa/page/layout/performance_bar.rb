# frozen_string_literal: true

module QA
  module Page
    module Layout
      class PerformanceBar < Page::Base
        view 'app/assets/javascripts/performance_bar/components/performance_bar_app.vue' do
          element 'performance-bar'
        end

        view 'app/assets/javascripts/performance_bar/components/detailed_metric.vue' do
          element 'detailed-metric-content'
        end

        view 'app/assets/javascripts/performance_bar/components/request_selector.vue' do
          element 'request-dropdown-option'
          element 'request-dropdown'
        end

        def has_performance_bar?
          has_element?('performance-bar')
        end

        def has_detailed_metrics?(minimum_count)
          retry_until(sleep_interval: 1) do
            all_elements(:'detailed-metric-content', minimum: minimum_count).all? do |metric|
              metric.has_text?(%r{\d+})
            end
          end
        end

        def has_request_for?(path)
          click_element('request-dropdown')
          retry_until(sleep_interval: 1) do
            has_element?('request-dropdown-option', text: path)
          end
        end
      end
    end
  end
end
