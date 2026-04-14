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

            def expand_right_sidebar
              wait_for_requests
              # Wait for initRightSidebar's 300ms setTimeout to fully collapse the sidebar
              wait_until(reload: false, max_duration: 2, sleep_interval: 0.1) do
                has_selector?('.right-sidebar.right-sidebar-collapsed', wait: 0)
              end
              retry_until(sleep_interval: 1, message: "Retry until right sidebar is expanded") do
                find('.js-sidebar-toggle').click unless has_selector?('.right-sidebar.right-sidebar-expanded', wait: 0)

                has_selector?('.right-sidebar.right-sidebar-expanded', wait: 0)
              end
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

            # No-op in CE; overridden by EE::Page::Component::DapEmptyState when prepended
            def close_dap_panel_if_exists; end
          end
        end
      end
    end
  end
end

QA::Page::Project::Monitor::Incidents::Show.prepend_mod_with('Page::Project::Monitor::Incidents::Show', namespace: QA)
