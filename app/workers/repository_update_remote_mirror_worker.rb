class RepositoryUpdateRemoteMirrorWorker
  UpdateRemoteMirrorError = Class.new(StandardError)

  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :project_mirror, retry: RemoteMirror::MAX_RETRIES

  sidekiq_retry_in do |count|
    RemoteMirror::BACKOFF_DELAY**count
  end

  def perform(remote_mirror_id, current_time)
    begin
      remote_mirror  = RemoteMirror.find(remote_mirror_id)
      last_update_at = remote_mirror.last_update_at
      project        = remote_mirror.project
      current_user   = project.creator

      return if last_update_at && last_update_at > current_time

      result = Projects::UpdateRemoteMirrorService.new(project, current_user).execute(remote_mirror)

      if result[:status] == :error
        remote_mirror.mark_as_failed(result[:message])
      else
        remote_mirror.update_finish
      end
    rescue => ex
      remote_mirror.mark_as_failed("We're sorry, a temporary error occurred, please try again.")

      raise UpdateRemoteMirrorError, "#{ex.class}: #{Gitlab::UrlSanitizer.sanitize(ex.message)}"
    end
  end
end
