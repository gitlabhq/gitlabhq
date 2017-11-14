class StuckImportJobsWorker
  include Sidekiq::Worker
  include CronjobQueue

  IMPORT_JOBS_EXPIRATION = 15.hours.to_i

  def perform
    projects_without_jid_count = mark_projects_without_jid_as_failed!
    projects_with_jid_count =  mark_projects_with_jid_as_failed!

    values = {
      projects_without_jid_count: projects_without_jid_count,
      projects_with_jid_count: projects_with_jid_count
    }

    Gitlab::Metrics.add_event_with_values(:stuck_import_jobs, values)

    stuck_import_jobs_worker_runs_counter.increment
    projects_without_jid_metric.set({}, projects_without_jid_count)
    projects_with_jid_metric.set({}, projects_with_jid_count)
  end

  private

  def mark_projects_without_jid_as_failed!
    enqueued_projects_without_jid.each do |project|
      project.mark_import_as_failed(error_message)
    end.count
  end

  def mark_projects_with_jid_as_failed!
    completed_jids_count = 0

    enqueued_projects_with_jid.find_in_batches(batch_size: 500) do |group|
      jids = group.map(&:import_jid)

      # Find the jobs that aren't currently running or that exceeded the threshold.
      completed_jids = Gitlab::SidekiqStatus.completed_jids(jids).to_set

      if completed_jids.any?
        completed_jids_count += completed_jids.count
        group.each do |project|
          project.mark_import_as_failed(error_message) if completed_jids.include?(project.import_jid)
        end

        Rails.logger.info("Marked stuck import jobs as failed. JIDs: #{completed_jids.to_a.join(', ')}")
      end
    end

    completed_jids_count
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

  def stuck_import_jobs_worker_runs_counter
    @stuck_import_jobs_worker_runs_counter ||= Gitlab::Metrics.counter(:gitlab_stuck_import_jobs_worker_runs_total,
                                                                       'Stuck import jobs worker runs count')
  end

  def projects_without_jid_metric
    @projects_without_jid_metric ||= Gitlab::Metrics.gauge(:gitlab_projects_without_jid, 'Projects without Job ids')
  end

  def projects_with_jid_metric
    @projects_with_jid_metric ||= Gitlab::Metrics.gauge(:gitlab_projects_with_jid, 'Projects with Job ids')
  end
end
