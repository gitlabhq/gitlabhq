# frozen_string_literal: true
module Ci
  module MergeRequests
    class AddTodoWhenBuildFailsWorker
      include ApplicationWorker

      sidekiq_options retry: 3
      include PipelineQueue

      urgency :low
      tags :exclude_from_kubernetes
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
