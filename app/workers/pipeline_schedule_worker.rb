# frozen_string_literal: true

class PipelineScheduleWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue
  include ::Gitlab::ExclusiveLeaseHelpers

  LOCK_RETRY = 3
  LOCK_TTL = 5.minutes

  feature_category :continuous_integration
  worker_resource_boundary :cpu

  def perform
    in_lock(lock_key, **lock_params) do
      Ci::PipelineSchedule
        .select(:id, :owner_id, :project_id) # Minimize the selected columns
        .runnable_schedules
        .preloaded
        .find_in_batches do |schedules|
          RunPipelineScheduleWorker.bulk_perform_async_with_contexts(
            schedules,
            arguments_proc: ->(schedule) { [schedule.id, schedule.owner_id, { scheduling: true }] },
            context_proc: ->(schedule) { { project: schedule.project, user: schedule.owner } }
          )
        end
    end
  end

  private

  def lock_key
    self.class.name.underscore
  end

  def lock_params
    {
      ttl: LOCK_TTL,
      retries: LOCK_RETRY
    }
  end
end
