class RepositoryUpdateRemoteMirrorWorker
  UpdateRemoteMirrorError = Class.new(StandardError)

  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :project_mirror, retry: 3

  sidekiq_retries_exhausted do |msg, e|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(remote_mirror_id, scheduled_time)
    begin
      remote_mirror = RemoteMirror.find(remote_mirror_id)
      return if remote_mirror.updated_since?(scheduled_time)

      remote_mirror.update_start

      project = remote_mirror.project
      current_user = project.creator
      result = Projects::UpdateRemoteMirrorService.new(project, current_user).execute(remote_mirror)

      raise UpdateRemoteMirrorError, result[:message] if result[:status] == :error

      remote_mirror.update_finish
    rescue UpdateRemoteMirrorError => ex
      remote_mirror.mark_as_failed(Gitlab::UrlSanitizer.sanitize(ex.message))
      raise
    rescue => ex
      raise UpdateRemoteMirrorError, "#{ex.class}: #{ex.message}"
    end
  end
end
