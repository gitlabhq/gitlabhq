# frozen_string_literal: true

class GitlabShellWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include Gitlab::ShellAdapter

  feature_category :source_code_management
  urgency :high
  weight 2
  loggable_arguments 0

  def perform(action, *arg)
    if ::Feature.enabled?(:verify_gitlab_shell_worker_method_names) && Gitlab::Shell::PERMITTED_ACTIONS.exclude?(action)
      raise(ArgumentError, "#{action} not allowed for #{self.class.name}")
    end

    Gitlab::GitalyClient::NamespaceService.allow do
      gitlab_shell.public_send(action, *arg) # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
