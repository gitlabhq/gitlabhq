# frozen_string_literal: true

module QA
  module Page
    module Project
      module Pipeline
        class Index < QA::Page::Base
          include Component::CiIcon

          view 'app/assets/javascripts/ci/pipelines_page/components/pipeline_url.vue' do
            element 'pipeline-url-link'
          end

          view 'app/assets/javascripts/ci/pipelines_page/components/nav_controls.vue' do
            element 'run-pipeline-button'
          end

          view 'app/assets/javascripts/ci/common/pipelines_table.vue' do
            element 'pipeline-table-row'
          end

          def latest_pipeline
            all_elements('pipeline-table-row', minimum: 1).first
          end

          def latest_pipeline_status
            within(latest_pipeline) do
              find_element('ci-icon-text')
            end.text
          end

          # If no status provided, wait for pipeline to complete
          def wait_for_latest_pipeline(status: nil, wait: nil, reload: false)
            wait ||= Support::Repeater::DEFAULT_MAX_WAIT_TIME
            finished_status = %w[passed failed canceled skipped manual warning]

            wait_until(max_duration: wait, reload: reload, sleep_interval: 1, message: "Wait for latest pipeline") do
              if status
                latest_pipeline_status.casecmp(status) == 0
              else
                finished_status.include?(latest_pipeline_status.downcase)
              end
            end
          end

          def has_any_pipeline?(wait: nil)
            wait ||= Support::Repeater::DEFAULT_MAX_WAIT_TIME
            wait_until(max_duration: wait, message: "Wait for any pipeline") do
              has_element?('pipeline-table-row')
            end
          end

          def has_no_pipeline?
            has_no_element?('pipeline-table-row')
          end

          def click_run_pipeline_button
            click_element('run-pipeline-button', Page::Project::Pipeline::New)
          end

          def click_on_latest_pipeline
            latest_pipeline.find(element_selector_css('pipeline-url-link')).click
          end
        end
      end
    end
  end
end
