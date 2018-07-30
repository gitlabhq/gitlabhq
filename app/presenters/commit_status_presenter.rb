# frozen_string_literal: true

class CommitStatusPresenter < Gitlab::View::Presenter::Delegated
  CALLOUT_FAILURE_MESSAGES = {
    unknown_failure: 'There is an unknown failure, please try again',
    script_failure: nil,
    api_failure: 'There has been an API failure, please try again',
    stuck_or_timeout_failure: 'There has been a timeout failure or the job got stuck. Check your timeout limits or try again',
    runner_system_failure: 'There has been a runner system failure, please try again',
    missing_dependency_failure: 'There has been a missing dependency failure',
    runner_unsupported: 'Your runner is outdated, please upgrade your runner'
  }.freeze

  presents :build

  def callout_failure_message
    CALLOUT_FAILURE_MESSAGES.fetch(failure_reason.to_sym)
  end

  def recoverable?
    failed? && !unrecoverable?
  end

  def unrecoverable?
    script_failure? || missing_dependency_failure? || runner_unsupported?
  end
end
