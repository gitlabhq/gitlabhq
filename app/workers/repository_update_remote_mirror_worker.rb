class RepositoryUpdateRemoteMirrorWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  def perform(remote_mirror_id)
    remote_mirror = RemoteMirror.find(remote_mirror_id)
    project       = remote_mirror.project
    current_user  = project.creator
    result        = Projects::UpdateRemoteMirrorService.new(project, current_user).execute(remote_mirror)

    if result[:status] == :error
      remote_mirror.mark_as_failed(result[:message])
    else
      remote_mirror.update_finish
    end
  end
end
