class GitlabShellWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter
  include DedicatedSidekiqQueue

  def perform(action, *arg)
    gitlab_shell.__send__(action, *arg) # rubocop:disable GitlabSecurity/PublicSend
  end
end
