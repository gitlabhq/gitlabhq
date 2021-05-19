# frozen_string_literal: true

module QA
  module Page
    module Project
      module Pipeline
        class Show < QA::Page::Base
          include Component::CiBadgeLink

          view 'app/assets/javascripts/vue_shared/components/header_ci_component.vue' do
            element :pipeline_header
          end

          view 'app/assets/javascripts/pipelines/components/graph/graph_component.vue' do
            element :pipeline_graph, /class.*pipeline-graph.*/ # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/pipelines/components/graph/job_item.vue' do
            element :job_item_container
            element :job_link
            element :action_button
          end

          view 'app/assets/javascripts/pipelines/components/graph/linked_pipeline.vue' do
            element :expand_pipeline_button
            element :child_pipeline
          end

          view 'app/assets/javascripts/reports/components/report_section.vue' do
            element :expand_report_button
          end

          view 'app/assets/javascripts/vue_shared/components/ci_icon.vue' do
            element :status_icon, 'ci-status-icon-${status}' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/views/projects/pipelines/_info.html.haml' do
            element :pipeline_badges
          end

          def running?(wait: 0)
            within_element(:pipeline_header) do
              page.has_content?('running', wait: wait)
            end
          end

          def has_build?(name, status: :success, wait: nil)
            if status
              within_element(:job_item_container, text: name) do
                has_selector?(".ci-status-icon-#{status}", { wait: wait }.compact)
              end
            else
              has_element?(:job_item_container, text: name)
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

          def has_child_pipeline?(title: nil)
            title ? find_child_pipeline_by_title(title) : has_element?(:child_pipeline)
          end

          def has_no_child_pipeline?
            has_no_element?(:child_pipeline)
          end

          def click_job(job_name)
            click_element(:job_link, Project::Job::Show, text: job_name)
          end

          def child_pipelines
            all_elements(:child_pipeline, minimum: 1)
          end

          def find_child_pipeline_by_title(title)
            child_pipelines.find { |pipeline| pipeline[:title].include?(title) }
          end

          def expand_child_pipeline(title: nil)
            child_pipeline = title ? find_child_pipeline_by_title(title) : child_pipelines.first

            within_element_by_index(:child_pipeline, child_pipelines.index(child_pipeline)) do
              click_element(:expand_pipeline_button)
            end
          end

          def expand_license_report
            within_element(:license_report_widget) do
              click_element(:expand_report_button)
            end
          end

          def click_on_first_job
            first('.js-pipeline-graph-job-link', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME).click
          end

          def click_job_action(job_name)
            within_element(:job_item_container, text: job_name) do
              click_element(:action_button)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Pipeline::Show.prepend_mod_with('Page::Project::Pipeline::Show', namespace: QA)
