class RepositoryUpdateMirrorWorker
  UpdateError = Class.new(StandardError)
  UpdateAlreadyInProgressError = Class.new(StandardError)

  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  # Retry not neccessary. It will try again at the next update interval.
  sidekiq_options queue: :project_mirror, retry: false

  attr_accessor :project, :repository, :current_user

  def perform(project_id)
    project = Project.find(project_id)

    raise UpdateAlreadyInProgressError if project.import_started?
    project.import_start

    @current_user = project.mirror_user || project.creator

    result = Projects::UpdateMirrorService.new(project, @current_user).execute
    raise UpdateError, result[:message] if result[:status] == :error

    project.import_finish
  rescue UpdateAlreadyInProgressError
    raise
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

  def fail_mirror(project, message)
    Rails.logger.error(message)
    project.mark_import_as_failed(message)
  end
end
