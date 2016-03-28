class GitlabShellOneShotWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell, retry: false

  def perform(action, *arg)
    gitlab_shell.send(action, *arg)
  end
end
