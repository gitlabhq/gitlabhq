# frozen_string_literal: true

module QA::Page
  module Project::Pipeline
    class Index < QA::Page::Base
      view 'app/assets/javascripts/pipelines/components/pipeline_url.vue' do
        element :pipeline_link, 'class="js-pipeline-url-link' # rubocop:disable QA/ElementWithPattern
      end

      def click_on_latest_pipeline
        css = '.js-pipeline-url-link'

        link = wait(reload: false) do
          first(css)
        end

        link.click
      end
    end
  end
end
