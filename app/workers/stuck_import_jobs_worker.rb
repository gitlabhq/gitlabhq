class StuckImportJobsWorker
  include ApplicationWorker
  include CronjobQueue

  IMPORT_JOBS_EXPIRATION = 15.hours.to_i

  def perform
    projects_without_jid_count = mark_projects_without_jid_as_failed!
    projects_with_jid_count = mark_projects_with_jid_as_failed!

    Gitlab::Metrics.add_event(:stuck_import_jobs,
                             projects_without_jid_count: projects_without_jid_count,
                             projects_with_jid_count: projects_with_jid_count)
  end

  private

  def mark_projects_without_jid_as_failed!
    enqueued_projects_without_jid.each do |project|
      project.mark_import_as_failed(error_message)
    end.count
  end

  def mark_projects_with_jid_as_failed!
    jids_and_ids = enqueued_projects_with_jid.pluck(:import_jid, :id).to_h

    # Find the jobs that aren't currently running or that exceeded the threshold.
    completed_jids = Gitlab::SidekiqStatus.completed_jids(jids_and_ids.keys)
    return unless completed_jids.any?

    completed_project_ids = jids_and_ids.values_at(*completed_jids)

    # We select the projects again, because they may have transitioned from
    # scheduled/started to finished/failed while we were looking up their Sidekiq status.
    completed_projects = enqueued_projects_with_jid.where(id: completed_project_ids)

    Rails.logger.info("Marked stuck import jobs as failed. JIDs: #{completed_projects.map(&:import_jid).join(', ')}")

    completed_projects.each do |project|
      project.mark_import_as_failed(error_message)
    end.count
  end

  def enqueued_projects
    Project.with_import_status(:scheduled, :started)
  end

  def enqueued_projects_with_jid
    enqueued_projects.where.not(import_jid: nil)
  end

  def enqueued_projects_without_jid
    enqueued_projects.where(import_jid: nil)
  end

  def error_message
    "Import timed out. Import took longer than #{IMPORT_JOBS_EXPIRATION} seconds"
  end
end
