# frozen_string_literal: true

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
    # TODO: Rollback this change to use SQL through #pluck
    jids_and_ids = enqueued_projects_with_jid.map { |project| [project.import_jid, project.id] }.to_h

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
    Project.joins_import_state.where("(import_state.status = 'scheduled' OR import_state.status = 'started') OR (projects.import_status = 'scheduled' OR projects.import_status = 'started')")
  end

  def enqueued_projects_with_jid
    enqueued_projects.where.not("import_state.jid IS NULL AND projects.import_jid IS NULL")
  end

  def enqueued_projects_without_jid
    enqueued_projects.where("import_state.jid IS NULL AND projects.import_jid IS NULL")
  end

  def error_message
    "Import timed out. Import took longer than #{IMPORT_JOBS_EXPIRATION} seconds"
  end
end
