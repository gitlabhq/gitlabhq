class RepositoryUpdateRemoteMirrorWorker
  UpdateRemoteMirrorError = Class.new(StandardError)

  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  BACKOFF_DELAY = 5.minutes.to_i
  MAX_RETRIES = 5

  sidekiq_options queue: :project_mirror, retry: MAX_RETRIES
  sidekiq_retry_in { |count| BACKOFF_DELAY**count }

  def perform(remote_mirror_id, current_time)
    begin
      remote_mirror = RemoteMirror.find(remote_mirror_id)
      return if remote_mirror&.last_update_at.to_i > current_time.to_i

      project = remote_mirror.project
      current_user = project.creator

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
