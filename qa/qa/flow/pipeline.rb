# frozen_string_literal: true

module QA
  module Flow
    module Pipeline
      extend self

      # Acceptable statuses:
      # Canceled, Created, Failed, Manual, Passed
      # Pending, Running, Skipped
      def visit_latest_pipeline(status: nil, wait: nil, skip_wait: true)
        Page::Project::Menu.perform(&:go_to_pipelines)
        Page::Project::Pipeline::Index.perform do |index|
          index.has_any_pipeline?(wait: wait)
          index.wait_for_latest_pipeline(status: status, wait: wait) if status || !skip_wait
          index.click_on_latest_pipeline
        end
      end

      def wait_for_latest_pipeline(status: nil, wait: nil)
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
    end
  end
end

QA::Flow::Pipeline.prepend_mod_with('Flow::Pipeline', namespace: QA)
