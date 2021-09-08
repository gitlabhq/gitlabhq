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
    unmet_prerequisites: 'The job failed to complete prerequisite tasks',
    scheduler_failure: 'The scheduler failed to assign job to the runner, please try again or contact system administrator',
    data_integrity_failure: 'There has been a structural integrity problem detected, please contact system administrator',
    forward_deployment_failure: 'The deployment job is older than the previously succeeded deployment job, and therefore cannot be run',
    pipeline_loop_detected: 'This job could not be executed because it would create infinitely looping pipelines',
    invalid_bridge_trigger: 'This job could not be executed because downstream pipeline trigger definition is invalid',
    downstream_bridge_project_not_found: 'This job could not be executed because downstream bridge project could not be found',
    insufficient_bridge_permissions: 'This job could not be executed because of insufficient permissions to create a downstream pipeline',
    bridge_pipeline_is_child_pipeline: 'This job belongs to a child pipeline and cannot create further child pipelines',
    downstream_pipeline_creation_failed: 'The downstream pipeline could not be created',
    secrets_provider_not_found: 'The secrets provider can not be found',
    reached_max_descendant_pipelines_depth: 'You reached the maximum depth of child pipelines',
    project_deleted: 'The job belongs to a deleted project',
    user_blocked: 'The user who created this job is blocked',
    ci_quota_exceeded: 'No more CI minutes available',
    no_matching_runner: 'No matching runner available',
    trace_size_exceeded: 'The job log size limit was reached'
  }.freeze

  private_constant :CALLOUT_FAILURE_MESSAGES

  presents :build

  def self.callout_failure_messages
    CALLOUT_FAILURE_MESSAGES
  end

  def callout_failure_message
    self.class.callout_failure_messages.fetch(failure_reason.to_sym)
  end
end

CommitStatusPresenter.prepend_mod_with('CommitStatusPresenter')
