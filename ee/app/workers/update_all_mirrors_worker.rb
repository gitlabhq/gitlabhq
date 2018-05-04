class UpdateAllMirrorsWorker
  include ApplicationWorker
  include CronjobQueue

  LEASE_TIMEOUT = 5.minutes
  SCHEDULE_WAIT_TIMEOUT = 4.minutes
  LEASE_KEY = 'update_all_mirrors'.freeze

  def perform
    lease_uuid = try_obtain_lease
    return unless lease_uuid

    schedule_mirrors!

    cancel_lease(lease_uuid)
  end

  def schedule_mirrors!
    capacity = Gitlab::Mirror.available_capacity

    # Ignore mirrors that become due for scheduling once work begins, so we
    # can't end up in an infinite loop
    now = Time.now
    last = nil
    all_project_ids = []

    while capacity > 0
      batch_size = [capacity * 2, 500].min
      projects = pull_mirrors_batch(freeze_at: now, batch_size: batch_size, offset_at: last).to_a
      break if projects.empty?

      project_ids = projects.lazy.select(&:mirror?).take(capacity).map(&:id).force
      capacity -= project_ids.length

      all_project_ids.concat(project_ids)

      # If fewer than `batch_size` projects were returned, we don't need to query again
      break if projects.length < batch_size

      last = projects.last.import_state.next_execution_timestamp
    end

    ProjectImportScheduleWorker.bulk_perform_and_wait(all_project_ids.map { |id| [id] }, timeout: SCHEDULE_WAIT_TIMEOUT.to_i)
  end

  private

  def try_obtain_lease
    ::Gitlab::ExclusiveLease.new(LEASE_KEY, timeout: LEASE_TIMEOUT).try_obtain
  end

  def cancel_lease(uuid)
    ::Gitlab::ExclusiveLease.cancel(LEASE_KEY, uuid)
  end

  def pull_mirrors_batch(freeze_at:, batch_size:, offset_at: nil)
    relation = Project
      .mirrors_to_sync(freeze_at)
      .reorder('import_state.next_execution_timestamp')
      .limit(batch_size)
      .includes(:namespace) # Used by `project.mirror?`

    relation = relation.where('import_state.next_execution_timestamp > ?', offset_at) if offset_at

    relation
  end
end
