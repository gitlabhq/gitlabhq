# frozen_string_literal: true

module QA
  module Page
    module Project
      module Pipeline
        class Show < QA::Page::Base
          include Component::CiBadgeLink

          view 'app/assets/javascripts/vue_shared/components/header_ci_component.vue' do
            element :pipeline_header, /header class.*ci-header-container.*/ # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/pipelines/components/graph/graph_component.vue' do
            element :pipeline_graph, /class.*pipeline-graph.*/ # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/pipelines/components/graph/job_item.vue' do
            element :job_component, /class.*ci-job-component.*/ # rubocop:disable QA/ElementWithPattern
            element :job_link
          end

          view 'app/assets/javascripts/pipelines/components/graph/linked_pipeline.vue' do
            element :linked_pipeline_button
          end

          view 'app/assets/javascripts/vue_shared/components/ci_icon.vue' do
            element :status_icon, 'ci-status-icon-${status}' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/views/projects/pipelines/_info.html.haml' do
            element :pipeline_badges
          end

          def running?(wait: 0)
            within('.ci-header-container') do
              page.has_content?('running', wait: wait)
            end
          end

          def has_build?(name, status: :success, wait: nil)
            within('.pipeline-graph') do
              within('.ci-job-component', text: name) do
                has_selector?(".ci-status-icon-#{status}", { wait: wait }.compact)
              end
            end
          end

          def has_job?(job_name)
            has_element?(:job_link, text: job_name)
          end

          def has_no_job?(job_name)
            has_no_element?(:job_link, text: job_name)
          end

          def has_tag?(tag_name)
            within_element(:pipeline_badges) do
              has_selector?('.badge', text: tag_name)
            end
          end

          def click_job(job_name)
            click_element(:job_link, text: job_name)
          end

          def click_linked_job(project_name)
            click_element(:linked_pipeline_button, text: /#{project_name}/)
          end

          def click_on_first_job
            first('.js-pipeline-graph-job-link', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME).click
          end
        end
      end
    end
  end
end

QA::Page::Project::Pipeline::Show.prepend_if_ee('QA::EE::Page::Project::Pipeline::Show')
