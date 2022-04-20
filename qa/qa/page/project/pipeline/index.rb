# frozen_string_literal: true

module QA
  module Page
    module Project
      module Pipeline
        class Index < QA::Page::Base
          view 'app/assets/javascripts/pipelines/components/pipelines_list/pipeline_url.vue' do
            element :pipeline_url_link
          end

          view 'app/assets/javascripts/pipelines/components/pipelines_list/pipelines_status_badge.vue' do
            element :pipeline_commit_status
          end

          view 'app/assets/javascripts/pipelines/components/pipelines_list/pipeline_operations.vue' do
            element :pipeline_retry_button
          end

          view 'app/assets/javascripts/pipelines/components/pipelines_list/nav_controls.vue' do
            element :run_pipeline_button
          end

          view 'app/assets/javascripts/pipelines/components/pipelines_list/pipelines_table.vue' do
            element :pipeline_row_container
          end

          def latest_pipeline
            all_elements(:pipeline_row_container, minimum: 1).first
          end

          def latest_pipeline_status
            latest_pipeline.find(element_selector_css(:pipeline_commit_status)).text
          end

          # If no status provided, wait for pipeline to complete
          def wait_for_latest_pipeline(status: nil, wait: nil, reload: false)
            wait ||= Support::Repeater::DEFAULT_MAX_WAIT_TIME
            finished_status = %w[passed failed canceled skipped manual]

            wait_until(max_duration: wait, reload: reload, sleep_interval: 1) do
              status ? latest_pipeline_status == status : finished_status.include?(latest_pipeline_status)
            end
          end

          def has_any_pipeline?(wait: nil)
            wait ||= Support::Repeater::DEFAULT_MAX_WAIT_TIME
            wait_until(max_duration: wait) { has_element?(:pipeline_row_container) }
          end

          def has_no_pipeline?
            has_no_element?(:pipeline_row_container)
          end

          def click_run_pipeline_button
            click_element(:run_pipeline_button, Page::Project::Pipeline::New)
          end

          def click_on_latest_pipeline
            latest_pipeline.find(element_selector_css(:pipeline_url_link)).click
          end
        end
      end
    end
  end
end
