# frozen_string_literal: true

module CommitStatusEnums
  # Returns the Hash to use for creating the `failure_reason` enum for
  # `CommitStatus`.
  def self.failure_reasons
    {
      unknown_failure: nil,
      script_failure: 1,
      api_failure: 2,
      stuck_or_timeout_failure: 3,
      runner_system_failure: 4,
      missing_dependency_failure: 5,
      runner_unsupported: 6,
      stale_schedule: 7,
      job_execution_timeout: 8,
      archived_failure: 9,
      unmet_prerequisites: 10,
      scheduler_failure: 11,
      data_integrity_failure: 12,
      forward_deployment_failure: 13,
      protected_environment_failure: 1_000,
      insufficient_bridge_permissions: 1_001,
      downstream_bridge_project_not_found: 1_002,
      invalid_bridge_trigger: 1_003,
      upstream_bridge_project_not_found: 1_004,
      insufficient_upstream_permissions: 1_005,
      bridge_pipeline_is_child_pipeline: 1_006,
      downstream_pipeline_creation_failed: 1_007
    }
  end
end
