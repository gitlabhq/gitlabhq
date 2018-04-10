module QA::Page
  module Project::Pipeline
    class Show < QA::Page::Base
      view 'app/assets/javascripts/vue_shared/components/header_ci_component.vue' do
        element :pipeline_header, /header class.*ci-header-container.*/
      end

      view 'app/assets/javascripts/pipelines/components/graph/graph_component.vue' do
        element :pipeline_graph, /class.*pipeline-graph.*/
      end

      view 'app/assets/javascripts/pipelines/components/graph/job_component.vue' do
        element :job_component, /class.*ci-job-component.*/
        element :job_link, /class.*js-pipeline-graph-job-link.*/
      end

      view 'app/assets/javascripts/vue_shared/components/ci_icon.vue' do
        element :status_icon, 'ci-status-icon-${status}'
      end

      def running?
        within('.ci-header-container') do
          return page.has_content?('running')
        end
      end

      def has_build?(name, status: :success)
        within('.pipeline-graph') do
          within('.ci-job-component', text: name) do
            return has_selector?(".ci-status-icon-#{status}")
          end
        end
      end

      def go_to_first_job
        css = '.js-pipeline-graph-job-link'

        wait(reload: false) do
          has_css?(css)
        end

        first(css).click
      end
    end
  end
end
