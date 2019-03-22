# frozen_string_literal: true

class CommitStatusPresenter < Gitlab::View::Presenter::Delegated
  CALLOUT_FAILURE_MESSAGES = {
    unknown_failure: 'There is an unknown failure, please try again',
    script_failure: nil,
    api_failure: 'There has been an API failure, please try again',
    stuck_or_timeout_failure: 'There has been a timeout failure or the job got stuck. Check your timeout limits or try again',
    runner_system_failure: 'There has been a runner system failure, please try again',
    missing_dependency_failure: 'There has been a missing dependency failure',
    runner_unsupported: 'Your runner is outdated, please upgrade your runner',
    stale_schedule: 'Delayed job could not be executed by some reason, please try again',
    job_execution_timeout: 'The script exceeded the maximum execution time set for the job',
    archived_failure: 'The job is archived and cannot be run',
    unmet_prerequisites: 'The job failed to complete prerequisite tasks'
  }.freeze

  private_constant :CALLOUT_FAILURE_MESSAGES

  presents :build

  def self.callout_failure_messages
    CALLOUT_FAILURE_MESSAGES
  end

  def callout_failure_message
    self.class.callout_failure_messages.fetch(failure_reason.to_sym)
  end

  def recoverable?
    failed? && !unrecoverable?
  end

  def unrecoverable?
    script_failure? || missing_dependency_failure? || archived_failure?
  end
end
