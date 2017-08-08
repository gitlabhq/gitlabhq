class RepositoryUpdateMirrorWorker
  UpdateError = Class.new(StandardError)

  include Sidekiq::Worker
  include Gitlab::ShellAdapter
  include DedicatedSidekiqQueue

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
    UpdateAllMirrorsWorker.perform_async if Gitlab::Mirror.threshold_reached?
  end

  private

  def start_mirror(project)
    if project.import_start
      Gitlab::Mirror.increment_metric(:mirrors_running, 'Mirrors running count')
      Rails.logger.info("Mirror update for #{project.full_path} started. Waiting duration: #{project.mirror_waiting_duration}")

      true
    else
      Rails.logger.info("Project #{project.full_path} was in inconsistent state: #{project.import_status}")
      false
    end
  end

  def fail_mirror(project, message)
    error_message = "Mirror update for #{project.full_path} failed with the following message: #{message}"
    project.mark_import_as_failed(error_message)

    Gitlab::Mirror.increment_metric(:mirrors_failed, 'Mirrors failed count')
    Rails.logger.error(error_message)
  end

  def finish_mirror(project)
    project.import_finish

    Gitlab::Mirror.increment_metric(:mirrors_finished, 'Mirrors successfully finished count')
    Rails.logger.info("Mirror update for #{project.full_path} successfully finished. Update duration: #{project.mirror_update_duration}}.")
  end
end
