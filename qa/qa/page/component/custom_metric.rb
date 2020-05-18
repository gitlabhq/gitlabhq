# frozen_string_literal: true

module QA
  module Page
    module Component
      module CustomMetric
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/custom_metrics/components/custom_metrics_form_fields.vue' do
            element :custom_metric_prometheus_title_field
            element :custom_metric_prometheus_query_field
            element :custom_metric_prometheus_y_label_field
            element :custom_metric_prometheus_unit_label_field
            element :custom_metric_prometheus_legend_label_field
          end
        end

        def add_custom_metric
          fill_element :custom_metric_prometheus_title_field, 'HTTP Requests Total'
          fill_element :custom_metric_prometheus_query_field, 'rate(http_requests_total[5m])'
          fill_element :custom_metric_prometheus_y_label_field, 'Requests/second'
          fill_element :custom_metric_prometheus_unit_label_field, 'req/sec'
          fill_element :custom_metric_prometheus_legend_label_field, 'HTTP requests'

          save_changes
        end

        def save_changes
          click_button(class: 'btn-success')
        end

        def delete_custom_metric
          click_button(class: 'btn-danger')
          within('.modal-content') { click_button(class: 'btn-danger') }
        end

        def edit_custom_metric
          fill_element :custom_metric_prometheus_title_field, ''
          fill_element :custom_metric_prometheus_title_field, 'Throughput'

          save_changes
        end
      end
    end
  end
end
