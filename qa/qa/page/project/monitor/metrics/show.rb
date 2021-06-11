# frozen_string_literal: true

require 'securerandom'

module QA
  module Page
    module Project
      module Monitor
        module Metrics
          class Show < Page::Base
            EXPECTED_TITLE = 'Memory Usage (Total)'
            LOADING_MESSAGE = 'Waiting for performance data'

            view 'app/assets/javascripts/monitoring/components/dashboard.vue' do
              element :prometheus_graphs
            end

            view 'app/assets/javascripts/monitoring/components/dashboard_header.vue' do
              element :dashboards_filter_dropdown
              element :environments_dropdown
              element :range_picker_dropdown
            end

            view 'app/assets/javascripts/monitoring/components/dashboard_actions_menu.vue' do
              element :actions_menu_dropdown
              element :edit_dashboard_button_enabled
            end

            view 'app/assets/javascripts/monitoring/components/duplicate_dashboard_form.vue' do
              element :duplicate_dashboard_filename_field
            end

            view 'app/assets/javascripts/monitoring/components/dashboard_panel.vue' do
              element :prometheus_graph_widgets
              element :prometheus_widgets_dropdown
              element :alert_widget_menu_item
              element :generate_chart_link_menu_item
            end

            view 'app/assets/javascripts/vue_shared/components/date_time_picker/date_time_picker.vue' do
              element :quick_range_item
            end

            view 'app/assets/javascripts/monitoring/components/variables_section.vue' do
              element :variables_content
              element :variable_item
            end

            def wait_for_metrics
              wait_for_data
              return if has_metrics?

              wait_until(max_duration: 180) do
                wait_for_data
                has_metrics?
              end
            end

            def has_metrics?
              within_element :prometheus_graphs do
                has_text?(EXPECTED_TITLE)
              end
            end

            def has_edit_dashboard_enabled?
              click_element :actions_menu_dropdown

              within_element :actions_menu_dropdown do
                has_element? :edit_dashboard_button_enabled
              end
            end

            def duplicate_dashboard(save_as = 'test_duplication.yml', commit_option = 'Commit to default branch')
              click_element :actions_menu_dropdown
              click_on 'Duplicate current dashboard'
              fill_element :duplicate_dashboard_filename_field, "#{SecureRandom.hex(8)}-#{save_as}"
              choose commit_option
              within('.modal-content') { click_button(class: 'btn-success') }
            end

            def select_dashboard(dashboard_name)
              click_element :dashboards_filter_dropdown

              within_element :dashboards_filter_dropdown do
                click_on dashboard_name
              end
            end

            def filter_environment(environment = 'production')
              click_element :environments_dropdown

              within_element :environments_dropdown do
                click_link_with_text environment
              end
            end

            def show_last(range = '8 hours')
              all_elements(:range_picker_dropdown, minimum: 1).first.click
              click_element :quick_range_item, text: range
            end

            def copy_link_to_first_chart
              all_elements(:prometheus_widgets_dropdown, minimum: 1).first.click
              find_element(:generate_chart_link_menu_item)['data-clipboard-text']
            end

            def has_custom_metric?(metric)
              within_element :prometheus_graphs do
                has_text?(metric)
              end
            end

            def has_templating_variable?(variable)
              within_element :variables_content do
                has_element?(:variable_item, text: variable)
              end
            end

            def has_template_metric?(metric)
              within_element :prometheus_graphs do
                has_text?(metric)
              end
            end

            private

            def wait_for_data
              wait_until(reload: false) { !has_text?(LOADING_MESSAGE) } if has_text?(LOADING_MESSAGE)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Monitor::Metrics::Show.prepend_mod_with('Page::Project::Monitor::Metrics::Show', namespace: QA)
