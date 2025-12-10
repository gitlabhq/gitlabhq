# frozen_string_literal: true

module QA
  module Page
    module Project
      module Monitor
        module Incidents
          class Show < Page::Base
            view 'app/assets/javascripts/sidebar/components/labels/labels_select_widget/dropdown_value.vue' do
              element 'selected-label-content'
            end

            view 'app/assets/javascripts/sidebar/components/labels/labels_select_widget/labels_select_root.vue' do
              element 'sidebar-labels'
            end

            view 'app/assets/javascripts/sidebar/components/severity/sidebar_severity_widget.vue' do
              element 'incident-severity'
              element 'severity-block-container'
            end

            def has_label?(label)
              wait_labels_block_finish_loading do
                has_element?('selected-label-content', label_name: label)
              end
            end

            def has_severity?(severity)
              wait_severity_block_finish_loading do
                has_element?('incident-severity', text: severity)
              end
            end

            private

            def wait_labels_block_finish_loading
              within_element('sidebar-labels') do
                wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                  finished_loading_block?
                  yield
                end
              end
            end

            def wait_severity_block_finish_loading
              within_element('severity-block-container') do
                wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                  finished_loading_block?
                  yield
                end
              end
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Monitor::Incidents::Show.prepend_mod_with('Page::Project::Monitor::Incidents::Show', namespace: QA)
