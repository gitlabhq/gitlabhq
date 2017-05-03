class RepositoryUpdateRemoteMirrorWorker
  UpdateAlreadyInProgressError = Class.new(StandardError)
  UpdateError = Class.new(StandardError)

  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :project_mirror, retry: 3, dead: false

  sidekiq_retry_in { |count| 30 * count }

  sidekiq_retries_exhausted do |msg, _|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(remote_mirror_id, scheduled_time)
    remote_mirror = RemoteMirror.find(remote_mirror_id)
    return if remote_mirror.updated_since?(scheduled_time)

    raise UpdateAlreadyInProgressError if remote_mirror.update_in_progress?
    remote_mirror.update_start

    project = remote_mirror.project
    current_user = project.creator
    result = Projects::UpdateRemoteMirrorService.new(project, current_user).execute(remote_mirror)

    raise UpdateError, result[:message] if result[:status] == :error
    remote_mirror.update_finish
  rescue UpdateAlreadyInProgressError
    raise
  rescue UpdateError => ex
    remote_mirror.mark_as_failed(Gitlab::UrlSanitizer.sanitize(ex.message))
    raise
  rescue => ex
    raise UpdateError, "#{ex.class}: #{ex.message}"
  end
end
