# frozen_string_literal: true

module QA
  module Page
    module Layout
      class PerformanceBar < Page::Base
        view 'app/assets/javascripts/performance_bar/components/performance_bar_app.vue' do
          element :performance_bar
        end

        view 'app/assets/javascripts/performance_bar/components/detailed_metric.vue' do
          element :performance_bar_detailed_metric
        end

        view 'app/assets/javascripts/performance_bar/components/request_selector.vue' do
          element :performance_bar_request
        end

        def has_performance_bar?
          has_element?(:performance_bar)
        end

        def has_detailed_metrics?
          all_elements(:performance_bar_detailed_metric).all? do |metric|
            metric.has_text?(%r{\d+})
          end
        end

        def has_request_for?(path)
          has_element?(:performance_bar_request, text: path)
        end
      end
    end
  end
end
