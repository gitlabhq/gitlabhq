# frozen_string_literal: true

module Ci
  class InitialPipelineProcessWorker
    include ApplicationWorker

    data_consistency :sticky
    sidekiq_options retry: 3
    queue_namespace :pipeline_processing
    feature_category :continuous_integration
    urgency :high
    loggable_arguments 1
    idempotent!

    # Reads the CI database from the primary, as PipelineProcessWorker does: a stale replica read of the
    # just-inserted jobs strands the pipeline in `created` because the service never reschedules.
    # Flag removal replaces this with `data_consistency :always, overrides: { main: :sticky }`:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/633873
    def self.get_data_consistency_per_database
      consistency = super
      return consistency unless Gitlab::Database.database_mode == Gitlab::Database::MODE_MULTIPLE_DATABASES
      return consistency unless Feature.enabled?(
        :initial_pipeline_process_worker_ci_primary_reads, Feature.current_request, type: :worker
      )

      consistency.merge(ci: :always)
    end

    def perform(pipeline_id)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::PipelineCreation::StartPipelineService
          .new(pipeline)
          .execute
      end
    end
  end
end
