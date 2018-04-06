class RepositoryUpdateMirrorWorker
  UpdateError = Class.new(StandardError)

  include ApplicationWorker
  include Gitlab::ShellAdapter
  include ProjectStartImport

  LEASE_KEY = 'repository_update_mirror_worker_start_scheduler'.freeze
  LEASE_TIMEOUT = 2.seconds

  # Retry not neccessary. It will try again at the next update interval.
  sidekiq_options retry: false, status_expiration: StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION

  attr_accessor :project, :repository, :current_user

  def perform(project_id)
    project = Project.find(project_id)

    return unless start_mirror(project)

    @current_user = project.mirror_user || project.creator

    result = Projects::UpdateMirrorService.new(project, @current_user).execute
    raise UpdateError, result[:message] if result[:status] == :error

    finish_mirror(project)
  rescue UpdateError => ex
    fail_mirror(project, ex.message)
    raise
  rescue => ex
    return unless project

    fail_mirror(project, ex.message)
    raise UpdateError, "#{ex.class}: #{ex.message}"
  ensure
    if !lease.exists? && Gitlab::Mirror.reschedule_immediately? && lease.try_obtain
      UpdateAllMirrorsWorker.perform_async
    end
  end

  private

  def lease
    @lease ||= ::Gitlab::ExclusiveLease.new(LEASE_KEY, timeout: LEASE_TIMEOUT)
  end

  def start_mirror(project)
    if start(project)
      Rails.logger.info("Mirror update for #{project.full_path} started. Waiting duration: #{project.mirror_waiting_duration}")
      metric_mirror_waiting_duration_seconds.observe({}, project.mirror_waiting_duration)

      Gitlab::Metrics.add_event_with_values(
        :mirrors_running,
        { duration: project.mirror_waiting_duration },
        { path: project.full_path })

      true
    else
      Rails.logger.info("Project #{project.full_path} was in inconsistent state: #{project.import_status}")
      false
    end
  end

  def fail_mirror(project, message)
    project.mark_import_as_failed(message)

    Rails.logger.error("Mirror update for #{project.full_path} failed with the following message: #{message}")
    Gitlab::Metrics.add_event(:mirrors_failed, path: project.full_path)
  end

  def finish_mirror(project)
    project.import_finish

    Rails.logger.info("Mirror update for #{project.full_path} successfully finished. Update duration: #{project.mirror_update_duration}}.")
    Gitlab::Metrics.add_event_with_values(
      :mirrors_finished,
      { duration: project.mirror_update_duration },
      { path: project.full_path })

    metric_mirror_update_duration_seconds.observe({}, project.mirror_update_duration)
  end

  def metric_mirror_update_duration_seconds
    @metric_mirror_update_duration_seconds ||= Gitlab::Metrics.histogram(
      :gitlab_repository_mirror_update_duration_seconds,
      'Mirror update duration',
      {},
      [0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 50.0, 100.0]
    )
  end

  def metric_mirror_waiting_duration_seconds
    @metric_mirror_waiting_duration_seconds ||= Gitlab::Metrics.histogram(
      :gitlab_repository_mirror_waiting_duration_seconds,
      'Waiting length for repository mirror',
      {},
      [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.500, 2.0, 10.0]
    )
  end
end
