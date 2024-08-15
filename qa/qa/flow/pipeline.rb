# frozen_string_literal: true

module QA
  module Flow
    module Pipeline
      extend self

      # Acceptable statuses:
      # Canceled, Created, Failed, Manual, Passed
      # Pending, Running, Skipped
      def visit_latest_pipeline(status: nil, wait: 120, skip_wait: true)
        Page::Project::Menu.perform(&:go_to_pipelines)
        Page::Project::Pipeline::Index.perform do |index|
          index.has_any_pipeline?(wait: wait)
          index.wait_for_latest_pipeline(status: status, wait: wait) if status || !skip_wait
          index.click_on_latest_pipeline
        end
      end

      def wait_for_latest_pipeline(status: nil, wait: 120)
        Page::Project::Menu.perform(&:go_to_pipelines)
        Page::Project::Pipeline::Index.perform do |index|
          index.has_any_pipeline?(wait: wait)
          index.wait_for_latest_pipeline(status: status, wait: wait)
        end
      end

      def visit_pipeline_job_page(job_name:, pipeline: nil)
        pipeline.visit! unless pipeline.nil?

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job(job_name)
        end
      end

      # With pipeline creation is slow a known issue - https://gitlab.com/groups/gitlab-org/-/epics/7290,
      # it might help reduce flakiness if we wait for pipeline to be created via API first before
      # visiting it via the UI.
      #
      # Trying to let it wait for up to 4 minutes, any longer than that is unacceptable in most scenarios.
      #
      # Provide a different size when more than 1 pipelines are expected.
      def wait_for_pipeline_creation(project:, size: 1, wait: 240)
        Support::Waiter.wait_until(message: 'Wait for pipeline to be created', max_duration: wait) do
          project.pipelines.present? && project.pipelines.size >= size
        end
      end
    end
  end
end

QA::Flow::Pipeline.prepend_mod_with('Flow::Pipeline', namespace: QA)
