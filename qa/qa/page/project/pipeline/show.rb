# frozen_string_literal: true

module QA
  module Page
    module Project
      module Pipeline
        class Show < QA::Page::Base
          include Component::CiBadgeLink

          view 'app/assets/javascripts/vue_shared/components/header_ci_component.vue' do
            element :pipeline_header, required: true
          end

          view 'app/views/projects/pipelines/_info.html.haml' do
            element :merge_request_badge_tag
          end

          view 'app/assets/javascripts/pipelines/components/graph/graph_component.vue' do
            element :pipeline_graph, /class.*pipeline-graph.*/ # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/pipelines/components/graph/job_item.vue' do
            element :job_item_container, required: true
            element :job_link, required: true
            element :job_action_button
          end

          view 'app/assets/javascripts/pipelines/components/graph/linked_pipeline.vue' do
            element :expand_linked_pipeline_button
            element :linked_pipeline_container
            element :downstream_title_content
          end

          view 'app/assets/javascripts/ci/reports/components/report_section.vue' do
            element :expand_report_button
          end

          view 'app/assets/javascripts/vue_shared/components/ci_icon.vue' do
            element :status_icon, 'ci-status-icon-${status}' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/pipelines/components/graph/job_group_dropdown.vue' do
            element :job_dropdown_container
            element :jobs_dropdown_menu
          end

          view 'app/views/layouts/nav/breadcrumbs/_breadcrumbs.html.haml' do
            element :breadcrumb_links_content
            element :breadcrumb_current_link
          end

          def pipeline_id
            within_element(:breadcrumb_links_content) do
              find_element(:breadcrumb_current_link).text.delete_prefix('#')
            end
          end

          def running?(wait: 0)
            within_element(:pipeline_header) do
              page.has_content?('running', wait: wait)
            end
          end

          def has_merge_request_badge_tag?
            has_element?(:merge_request_badge_tag)
          end

          def has_build?(name, status: :success, wait: nil)
            if status
              within_element(:job_item_container, text: name) do
                has_selector?(".ci-status-icon-#{status}", **{ wait: wait }.compact)
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

          def linked_pipelines
            all_elements(:linked_pipeline_container, minimum: 1)
          end

          def find_linked_pipeline_by_title(title)
            linked_pipelines.find do |pipeline|
              within(pipeline) do
                find_element(:downstream_title_content).text.include?(title)
              end
            end
          end

          def has_linked_pipeline?(title: nil)
            # If the pipeline page has loaded linked pipelines should appear, but it can take a little while,
            # especially on busier environments.
            retry_until(reload: true, message: 'Waiting for linked pipeline to appear') do
              title ? find_linked_pipeline_by_title(title) : has_element?(:linked_pipeline_container)
            end
          end

          alias_method :has_child_pipeline?, :has_linked_pipeline?

          def has_no_linked_pipeline?
            has_no_element?(:linked_pipeline_container)
          end

          alias_method :has_no_child_pipeline?, :has_no_linked_pipeline?

          def expand_linked_pipeline(title: nil)
            linked_pipeline = title ? find_linked_pipeline_by_title(title) : linked_pipelines.first

            within_element_by_index(:linked_pipeline_container, linked_pipelines.index(linked_pipeline)) do
              click_element(:expand_linked_pipeline_button)
            end
          end

          alias_method :expand_child_pipeline, :expand_linked_pipeline

          def expand_license_report
            within_element(:license_report_widget) do
              click_element(:expand_report_button)
            end
          end

          def click_on_first_job
            first('.js-pipeline-graph-job-link', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME).click
          end

          def click_job(job_name)
            # Retry due to transient bug https://gitlab.com/gitlab-org/gitlab/-/issues/347126
            QA::Support::Retrier.retry_on_exception do
              click_element(:job_link, Project::Job::Show, text: job_name)
            end
          end

          def click_job_action(job_name)
            wait_for_requests

            within_element(:job_item_container, text: job_name) do
              click_element(:job_action_button)
            end
          end

          def click_job_dropdown(job_dropdown_name)
            click_element(:job_dropdown_container, text: job_dropdown_name)
          end

          def has_skipped_job_in_group?
            within_element(:jobs_dropdown_menu) do
              all_elements(:job_item_container, minimum: 1).all? do
                has_selector?('.ci-status-icon-skipped')
              end
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Pipeline::Show.prepend_mod_with('Page::Project::Pipeline::Show', namespace: QA)
