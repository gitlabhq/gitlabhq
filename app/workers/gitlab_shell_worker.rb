# frozen_string_literal: true

class GitlabShellWorker
  include ApplicationWorker
  include Gitlab::ShellAdapter

  feature_category :source_code_management
  latency_sensitive_worker!

  def perform(action, *arg)
    Gitlab::GitalyClient::NamespaceService.allow do
      gitlab_shell.__send__(action, *arg) # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
