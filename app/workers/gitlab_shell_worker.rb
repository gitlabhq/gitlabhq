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
    # Gitlab::Shell is being removed but we need to continue to process jobs
    # enqueued in the previous release, so handle them here.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/25095 for more details
    if AuthorizedKeysWorker::PERMITTED_ACTIONS.include?(action.to_s)
      AuthorizedKeysWorker.new.perform(action, *arg)

      return
    end

    Gitlab::GitalyClient::NamespaceService.allow do
      gitlab_shell.__send__(action, *arg) # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
