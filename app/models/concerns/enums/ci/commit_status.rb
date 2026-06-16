# frozen_string_literal: true
module Enums
  module Ci
    module CommitStatus
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
          forward_deployment_failure: 13, # Deprecated in favor of failed_outdated_deployment_job.
          user_blocked: 14,
          project_deleted: 15,
          ci_quota_exceeded: 16,
          pipeline_loop_detected: 17,
          no_matching_runner: 18,
          trace_size_exceeded: 19,
          builds_disabled: 20,
          environment_creation_failure: 21,
          deployment_rejected: 22,
          failed_outdated_deployment_job: 23,
          job_execution_server_timeout: 24,
          stuck_pending_with_matching_runners: 25,
          stuck_pending_no_matching_runners: 26,
          no_updates_running: 27,
          no_updates_canceling: 28,
          server_timeout_running: 29,
          server_timeout_canceling: 30,
          runner_configuration_error: 31,
          runner_external_dependency_failure: 32,
          runner_interrupted: 33,
          protected_environment_failure: 1_000,
          insufficient_bridge_permissions: 1_001,
          downstream_bridge_project_not_found: 1_002,
          invalid_bridge_trigger: 1_003,
          upstream_bridge_project_not_found: 1_004,
          insufficient_upstream_permissions: 1_005,
          bridge_pipeline_is_child_pipeline: 1_006, # not used anymore, but cannot be deleted because of old data
          downstream_pipeline_creation_failed: 1_007,
          secrets_provider_not_found: 1_008,
          reached_max_descendant_pipelines_depth: 1_009,
          ip_restriction_failure: 1_010,
          reached_max_pipeline_hierarchy_size: 1_011,
          reached_downstream_pipeline_trigger_rate_limit: 1_012,
          duo_workflow_not_allowed: 1_013,
          job_router_failure: 1_014,
          job_token_expired: 1_015,
          id_token_burned_project_path: 1_016,
          downstream_project_trigger_resolved_to_empty: 1_017
        }
      end

      # Maps a legacy `failure_reason` to the set of more specific reasons that
      # replaced it. When a broad reason is split into granular ones, new builds
      # stop being written with the legacy value, but it must keep working
      # wherever users reference failure reasons (for example `retry:when` in
      # `.gitlab-ci.yml`). Listing the legacy reason here makes it behave as an
      # alias that matches any of the reasons that superseded it, preserving the
      # original intent without re-emitting the legacy value.
      #
      # Add an entry whenever a failure reason is split, so the old name keeps
      # matching the failures it used to.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/602133.
      def self.failure_reason_aliases
        {
          'stuck_or_timeout_failure' => %w[
            stuck_pending_with_matching_runners
            stuck_pending_no_matching_runners
            no_updates_running
            no_updates_canceling
          ],
          'job_execution_timeout' => %w[
            server_timeout_running
            server_timeout_canceling
          ]
        }.freeze
      end
    end
  end
end
