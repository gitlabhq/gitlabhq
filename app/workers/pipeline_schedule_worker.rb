# frozen_string_literal: true

class PipelineScheduleWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue
  include ::Gitlab::ExclusiveLeaseHelpers

  LOCK_RETRY = 3
  LOCK_TTL = 5.minutes
  DELAY = 7.seconds
  BATCH_SIZE = 500

  feature_category :continuous_integration
  worker_resource_boundary :cpu

  def perform
    in_lock(lock_key, **lock_params) do
      Ci::PipelineSchedule
        .select(:id, :owner_id, :project_id) # Minimize the selected columns
        .runnable_schedules
        .preloaded
        .find_in_batches(batch_size: BATCH_SIZE).with_index do |schedules, index| # rubocop: disable CodeReuse/ActiveRecord -- activates because of batch_size
          active_schedules = schedules_for_active_projects(schedules)

          enqueue_run_pipeline_schedule_worker(active_schedules, index)
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

  # Can't join across databases, so look up active project ids instead.
  def schedules_for_active_projects(schedules)
    active_project_ids = Project.id_in(schedules.pluck(:project_id).uniq).non_archived.ids.to_set # rubocop:disable CodeReuse/ActiveRecord -- schedules is a plain array, not a model

    schedules.select { |schedule| active_project_ids.include?(schedule.project_id) }
  end

  def enqueue_run_pipeline_schedule_worker(schedules, index)
    RunPipelineScheduleWorker.bulk_perform_in_with_contexts(
      [1, index * DELAY].max,
      schedules,
      arguments_proc: ->(schedule) { [schedule.id, schedule.owner_id, { scheduling: true }] },
      context_proc: ->(schedule) { { project: schedule.project, user: schedule.owner } }
    )
  end
end
