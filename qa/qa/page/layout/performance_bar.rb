# frozen_string_literal: true

module QA
  module Page
    module Layout
      class PerformanceBar < Page::Base
        view 'app/assets/javascripts/performance_bar/components/performance_bar_app.vue' do
          element :performance_bar
        end

        view 'app/assets/javascripts/performance_bar/components/detailed_metric.vue' do
          element :detailed_metric_content
        end

        view 'app/assets/javascripts/performance_bar/components/request_selector.vue' do
          element :request_dropdown_option
          element :request_dropdown
        end

        def has_performance_bar?
          has_element?(:performance_bar)
        end

        def has_detailed_metrics?
          retry_until(sleep_interval: 1) do
            all_elements(:detailed_metric_content).all? do |metric|
              metric.has_text?(%r{\d+})
            end
          end
        end

        def has_request_for?(path)
          click_element(:request_dropdown)
          retry_until(sleep_interval: 1) do
            has_element?(:request_dropdown_option, text: path)
          end
        end
      end
    end
  end
end
