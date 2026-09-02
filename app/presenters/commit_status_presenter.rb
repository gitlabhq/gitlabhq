# frozen_string_literal: true

class CommitStatusPresenter < Gitlab::View::Presenter::Delegated
  CALLOUT_FAILURE_MESSAGES = {
    unknown_failure: N_('Job|There is an unknown failure, please try again'),
    script_failure: nil,
    api_failure: N_('Job|There has been an API failure, please try again'),
    stuck_or_timeout_failure: N_('Job|There has been a timeout failure or the job got stuck. Check your timeout limits or try again'),
    runner_system_failure: N_('Job|There has been a runner system failure, please try again'),
    runner_configuration_error: N_('Job|There has been a configuration error. Check your job configuration or contact your runner administrator.'),
    runner_external_dependency_failure: N_('Job|The runner could not reach an external dependency. Please try again.'),
    runner_interrupted: N_('Job|The runner process was interrupted before this job could finish. The job is safe to retry.'),
    missing_dependency_failure: N_('Job|There has been a missing dependency failure'),
    runner_unsupported: N_('Job|No runners support the requirements to run this job.'),
    stale_schedule: N_('Job|Delayed job could not be executed by some reason, please try again'),
    job_execution_timeout: N_('Job|The script exceeded the maximum execution time set for the job'),
    job_execution_server_timeout: N_('Job|The script exceeded the maximum execution time set for the job'),
    stuck_pending_with_matching_runners: N_('Job|The job was stuck in pending state with matching runners available. Check your job configuration or try again'),
    stuck_pending_no_matching_runners: N_('Job|The job was stuck in pending state with no matching runners available. Check your runner tags or configuration'),
    no_updates_running: N_('Job|The job was running but showed no activity for an extended period. Check your job script or try again'),
    no_updates_canceling: N_('Job|The job was canceling but showed no activity for an extended period. Try again'),
    server_timeout_running: N_('Job|The running job exceeded the maximum execution time set for the job'),
    server_timeout_canceling: N_('Job|The canceling job exceeded the maximum execution time set for the job'),
    archived_failure: N_('Job|The job is archived and cannot be run'),
    unmet_prerequisites: N_('Job|The job failed to complete prerequisite tasks'),
    scheduler_failure: N_('Job|The scheduler failed to assign job to the runner, please try again or contact system administrator'),
    data_integrity_failure: N_('Job|There has been an unknown job problem, please contact your system administrator with the job ID to review the logs'),
    forward_deployment_failure: N_('Job|The deployment job is older than the previously succeeded deployment job, and therefore cannot be run'),
    pipeline_loop_detected: N_('Job|This job could not be executed because it would create infinitely looping pipelines'),
    insufficient_upstream_permissions: N_('Job|This job could not be executed because of insufficient permissions to track the upstream project.'),
    upstream_bridge_project_not_found: N_('Job|This job could not be executed because upstream bridge project could not be found.'),
    invalid_bridge_trigger: N_('Job|This job could not be executed because downstream pipeline trigger definition is invalid'),
    downstream_project_trigger_resolved_to_empty: N_('Job|This job could not be executed because the trigger:project value resolved to a blank value. Check that the variables or inputs used in trigger:project are set.'),
    downstream_bridge_project_not_found: N_('Job|This job could not be executed because downstream bridge project could not be found'),
    protected_environment_failure: N_('Job|The environment this job is deploying to is protected. Only users with permission may successfully run this job.'),
    insufficient_bridge_permissions: N_('Job|This job could not be executed because of insufficient permissions to create a downstream pipeline'),
    bridge_pipeline_is_child_pipeline: N_('Job|This job belongs to a child pipeline and cannot create further child pipelines'),
    downstream_pipeline_creation_failed: N_('Job|The downstream pipeline could not be created'),
    secrets_provider_not_found: N_('Job|The secrets provider can not be found. Check your CI/CD variables and try again.'),
    secrets_manager_access_denied: N_('Job|This job could not retrieve secrets because the namespace does not have access to GitLab Secrets Manager. To restore access, start a trial or purchase GitLab Secrets Manager for the top-level group, or make sure the group has GitLab credits available and on-demand billing enabled.'),
    reached_max_descendant_pipelines_depth: N_('Job|You reached the maximum depth of child pipelines'),
    reached_max_pipeline_hierarchy_size: N_('Job|The downstream pipeline tree is too large'),
    project_deleted: N_('Job|The job belongs to a deleted project'),
    user_blocked: N_('Job|The user who created this job is blocked'),
    ci_quota_exceeded: N_('Job|No more compute minutes available'),
    no_matching_runner: N_('Job|No matching runner available'),
    trace_size_exceeded: N_('Job|The job log size limit was reached'),
    builds_disabled: N_('Job|The CI/CD is disabled for this project'),
    environment_creation_failure: N_('Job|This job could not be executed because it would create an environment with an invalid parameter.'),
    deployment_rejected: N_('Job|This deployment job was rejected.'),
    ip_restriction_failure: N_("Job|This job could not be executed because group IP address restrictions are enabled, and the runner's IP address is not in the allowed range."),
    duo_workflow_not_allowed: N_("Job|Duo Agent Platform cannot run on this runner. Duo jobs can only run on instance wide or top level group runners. Be sure to remove the gitlab--duo tag from this runner to avoid it picking these jobs."),
    duo_workflow_connection_failure: N_('Job|The Duo Workflow job failed because the runner could not connect to the Duo Agent Platform. Check your network configuration and try again.'),
    failed_outdated_deployment_job: N_('Job|The deployment job is older than the latest deployment, and therefore failed.'),
    reached_downstream_pipeline_trigger_rate_limit: N_('Job|Too many downstream pipelines triggered in the last minute. Try again later.'),
    job_router_failure: N_('Job|The Job Router failed to run this job.'),
    job_token_expired: N_('Job|The CI job token has expired. The job may have exceeded the maximum time limit.'),
    id_token_burned_project_path: N_('Job|ID token issuance is disabled in CI because this project\'s path was previously used by a different project. ' \
      'To restore ID tokens, set `ci_id_token_sub_claim_components` to start with `project_id` ' \
      '(for example, `["project_id", "ref_type", "ref"]`) and update your cloud trust policy to match.')
  }.freeze

  private_constant :CALLOUT_FAILURE_MESSAGES

  presents ::CommitStatus

  # Values are `N_` msgids, not display text. Jobs are serialized in bulk, so we
  # translate the single message we need in `#callout_failure_message` rather
  # than building a translated hash per job.
  def self.callout_failure_messages
    CALLOUT_FAILURE_MESSAGES
  end

  def callout_failure_message
    failure_reason.to_sym.then do |failure_reason|
      message = self.class.callout_failure_messages.fetch(failure_reason)
      message = s_(message) if message

      # Include custom error message from job_messages only for job_router_failure
      message = "#{message} #{job_router_failure_msg}" if failure_reason == :job_router_failure

      if doc_link = troubleshooting_doc[failure_reason]
        message += " #{help_page_link(doc_link)}"
      end

      message
    end
  end

  private

  def job_router_failure_msg
    if respond_to?(:error_job_messages) && error_job_messages.any?
      error_job_messages.first.content
    else
      s_('Job|Please contact your administrator.')
    end
  end

  def troubleshooting_doc
    {
      environment_creation_failure: help_page_path('ci/environments/_index.md', anchor: 'error-job-would-create-an-environment-with-an-invalid-parameter'),
      failed_outdated_deployment_job: help_page_path('ci/environments/deployment_safety.md', anchor: 'prevent-outdated-deployment-jobs'),
      secrets_manager_access_denied: help_page_path('ci/secrets/secrets_manager/_index.md', anchor: 'error-namespace-does-not-have-access-to-gitlab-secrets-manager'),
      id_token_burned_project_path: help_page_path(
        'ci/secrets/id_token_authentication.md',
        anchor: 'error-id-token-issuance-is-disabled'
      )
    }.freeze
  end

  def help_page_link(doc_link)
    ActionController::Base.helpers.link_to(s_('Job|How do I fix it?'), doc_link)
  end
end
