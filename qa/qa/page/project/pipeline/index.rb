# frozen_string_literal: true

module QA::Page
  module Project::Pipeline
    class Index < QA::Page::Base
      view 'app/assets/javascripts/pipelines/components/pipeline_url.vue' do
        element :pipeline_link, 'class="js-pipeline-url-link' # rubocop:disable QA/ElementWithPattern
      end

      view 'app/assets/javascripts/pipelines/components/pipelines_table_row.vue' do
        element :pipeline_commit_status
        element :pipeline_retry_button
      end

      def click_on_latest_pipeline
        css = '.js-pipeline-url-link'

        first(css, wait: 60).click
      end

      def wait_for_latest_pipeline_success
        wait_for_latest_pipeline_status { has_text?('passed') }
      end

      def wait_for_latest_pipeline_completion
        wait_for_latest_pipeline_status { has_text?('passed') || has_text?('failed') }
      end

      def wait_for_latest_pipeline_status
        wait_until(reload: false, max_duration: 300) do
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
    end
  end
end
