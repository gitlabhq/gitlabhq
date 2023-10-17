# frozen_string_literal: true

module Ci
  module MergeRequests
    class AddTodoWhenBuildFailsWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include PipelineQueue

      urgency :low
      idempotent!

      def perform(job_id)
        job = ::CommitStatus.with_pipeline.find_by_id(job_id)
        project = job&.project

        return unless job && project

        ::MergeRequests::AddTodoWhenBuildFailsService.new(project: job.project).execute(job)
      end
    end
  end
end
