# frozen_string_literal: true

module QA
  module Flow
    module Pipeline
      extend self

      AVAILABLE_STATUSES = %w[created waiting_for_resource preparing waiting_for_callback pending running success
        failed canceling canceled skipped manual scheduled].freeze

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

      # With pipeline creation is slow a known issue - https://gitlab.com/groups/gitlab-org/-/epics/7290,
      # it might help reduce flakiness if we wait for pipeline to be created via API first before
      # visiting it via the UI.
      #
      # Trying to let it wait for up to 4 minutes, any longer than that is unacceptable in most scenarios.
      #
      # Provide a different size when more than 1 pipelines are expected.
      def wait_for_pipeline_creation_via_api(project:, size: 1, wait: 240)
        Runtime::Logger.info("Waiting for #{project.name}'s latest pipeline to be created...")
        Support::Waiter.wait_until(message: 'Wait for pipeline to be created', max_duration: wait) do
          project.pipelines.present? && project.pipelines.size >= size
        end
      end

      def wait_for_latest_pipeline_to_have_status(project:, status: nil, wait: 240)
        wait_for_pipeline_status(
          project: project,
          status: status,
          wait: wait,
          pipeline_finder: -> { project.latest_pipeline }
        )
      end

      def wait_for_pipeline_to_have_status_by_source_branch(project:, source_branch:, status: nil, wait: 240)
        wait_for_pipeline_status(
          project: project,
          status: status,
          wait: wait,
          pipeline_finder: -> { project.pipelines.find { |p| p[:ref] == source_branch } },
          pipeline_identifier: source_branch
        )
      end

      def wait_for_pipeline_to_have_status_by_id(project:, pipeline_id:, status: nil, wait: 240)
        wait_for_pipeline_status(
          project: project,
          status: status,
          wait: wait,
          pipeline_finder: -> { project.pipelines.find { |p| p[:id] == pipeline_id } },
          pipeline_identifier: pipeline_id
        )
      end

      def wait_for_latest_pipeline_to_start(project:, wait: 240)
        Runtime::Logger.info("Waiting for #{project.name}'s latest pipeline to start...")
        wait_for_latest_pipeline_to_have_status(project: project, status: 'running', wait: wait)
      end

      # To wait for pipeline to complete regardless of status
      #
      def wait_for_latest_pipeline_to_finish(project:, wait: 240)
        Runtime::Logger.info("Waiting for #{project.name}'s latest pipeline to finish...")
        Support::Waiter.wait_until(message: 'Wait for latest pipeline to run', max_duration: wait) do
          pipeline = project.latest_pipeline
          pipeline[:started_at].present? && pipeline[:finished_at].present?
        end
      end

      private

      def wait_for_pipeline_status(project:, status:, wait:, pipeline_finder:, pipeline_identifier: 'latest')
        raise "'#{status}' is an invalid pipeline status." if AVAILABLE_STATUSES.exclude?(status)

        pipeline_desc = pipeline_identifier == 'latest' ? 'latest pipeline' : "pipeline #{pipeline_identifier}"
        Runtime::Logger.info("Waiting for #{project.name}'s #{pipeline_desc} to have status #{status}...")

        Support::Waiter.wait_until(
          message: "Wait for #{pipeline_desc} to have status #{status}",
          max_duration: wait
        ) do
          pipeline = pipeline_finder.call
          pipeline && pipeline[:status] == status
        end
      end
    end
  end
end

QA::Flow::Pipeline.prepend_mod_with('Flow::Pipeline', namespace: QA)
