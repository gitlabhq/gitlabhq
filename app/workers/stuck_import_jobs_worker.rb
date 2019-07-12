# frozen_string_literal: true

class StuckImportJobsWorker
  include ApplicationWorker
  include CronjobQueue

  IMPORT_JOBS_EXPIRATION = 15.hours.to_i

  def perform
    import_state_without_jid_count = mark_import_states_without_jid_as_failed!
    import_state_with_jid_count = mark_import_states_with_jid_as_failed!

    Gitlab::Metrics.add_event(:stuck_import_jobs,
                             projects_without_jid_count: import_state_without_jid_count,
                             projects_with_jid_count: import_state_with_jid_count)
  end

  private

  def mark_import_states_without_jid_as_failed!
    enqueued_import_states_without_jid.each do |import_state|
      import_state.mark_as_failed(error_message)
    end.count
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def mark_import_states_with_jid_as_failed!
    jids_and_ids = enqueued_import_states_with_jid.pluck(:jid, :id).to_h

    # Find the jobs that aren't currently running or that exceeded the threshold.
    completed_jids = Gitlab::SidekiqStatus.completed_jids(jids_and_ids.keys)
    return unless completed_jids.any?

    completed_import_state_ids = jids_and_ids.values_at(*completed_jids)

    # We select the import states again, because they may have transitioned from
    # scheduled/started to finished/failed while we were looking up their Sidekiq status.
    completed_import_states = enqueued_import_states_with_jid.where(id: completed_import_state_ids)

    completed_import_state_jids = completed_import_states.map { |import_state| import_state.jid }.join(', ')
    Rails.logger.info("Marked stuck import jobs as failed. JIDs: #{completed_import_state_jids}") # rubocop:disable Gitlab/RailsLogger

    completed_import_states.each do |import_state|
      import_state.mark_as_failed(error_message)
    end.count
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def enqueued_import_states
    ProjectImportState.with_status([:scheduled, :started])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def enqueued_import_states_with_jid
    enqueued_import_states.where.not(jid: nil)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def enqueued_import_states_without_jid
    enqueued_import_states.where(jid: nil)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def error_message
    _("Import timed out. Import took longer than %{import_jobs_expiration} seconds") % { import_jobs_expiration: IMPORT_JOBS_EXPIRATION }
  end
end
