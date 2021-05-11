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

          def click_on_latest_pipeline
            all_elements(:pipeline_url_link, minimum: 1, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME).first.click
          end

          def wait_for_latest_pipeline_succeeded
            wait_for_latest_pipeline_status { has_text?('passed') }
          end

          def wait_for_latest_pipeline_completed
            wait_for_latest_pipeline_status { has_text?('passed') || has_text?('failed') }
          end

          def wait_for_latest_pipeline_status
            wait_until(max_duration: 90, reload: true, sleep_interval: 5) { has_pipeline? }

            wait_until(reload: false, max_duration: 360) do
              within_element_by_index(:pipeline_commit_status, 0) { yield }
            end
          end

          def wait_for_latest_pipeline_success_or_retry
            wait_for_latest_pipeline_completion

            if has_text?('failed')
              click_element :pipeline_retry_button
              wait_for_latest_pipeline_success
            end
          end

          def has_pipeline?
            has_element? :pipeline_url_link
          end

          def has_no_pipeline?
            has_no_element? :pipeline_url_link
          end

          def click_run_pipeline_button
            click_element :run_pipeline_button, Page::Project::Pipeline::New
          end
        end
      end
    end
  end
end

QA::Page::Project::Pipeline::Index.prepend_mod_with('Page::Project::Pipeline::Index', namespace: QA)
