# frozen_string_literal: true
module Ci
  module MergeRequests
    class AddTodoWhenBuildFailsWorker
      include ApplicationWorker
      include PipelineQueue

      urgency :low
      idempotent!

      def perform(job_id)
        job = ::CommitStatus.with_pipeline.find_by_id(job_id)
        project = job&.project

        return unless job && project

        ::MergeRequests::AddTodoWhenBuildFailsService.new(job.project, nil).execute(job)
      end
    end
  end
end
