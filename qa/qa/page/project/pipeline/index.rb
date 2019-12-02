# frozen_string_literal: true

module QA::Page
  module Project::Pipeline
    class Index < QA::Page::Base
      view 'app/assets/javascripts/pipelines/components/pipeline_url.vue' do
        element :pipeline_link, 'class="js-pipeline-url-link' # rubocop:disable QA/ElementWithPattern
      end

      view 'app/assets/javascripts/pipelines/components/pipelines_table_row.vue' do
        element :pipeline_commit_status
      end

      def click_on_latest_pipeline
        css = '.js-pipeline-url-link'

        first(css, wait: 60).click
      end

      def wait_for_latest_pipeline_success
        wait(reload: false, max: 300) do
          within_element_by_index(:pipeline_commit_status, 0) do
            has_text?('passed')
          end
        end
      end
    end
  end
end
