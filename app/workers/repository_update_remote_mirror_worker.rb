class RepositoryUpdateRemoteMirrorWorker
  class UpdateRemoteMirrorError < StandardError; end

  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  def perform(remote_mirror_id)
    begin
      remote_mirror = RemoteMirror.find(remote_mirror_id)
      project       = remote_mirror.project
      current_user  = project.creator
      result        = Projects::UpdateRemoteMirrorService.new(project, current_user).execute(remote_mirror)

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
