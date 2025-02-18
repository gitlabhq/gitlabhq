# frozen_string_literal: true

module Enums
  module Ci
    module Pipeline
      # Returns the `Hash` to use for creating the `failure_reason` enum for
      # `Ci::Pipeline`.
      def self.failure_reasons
        {
          unknown_failure: 0,
          config_error: 1,
          external_validation_failure: 2,
          user_not_verified: 3,
          size_limit_exceeded: 21,
          job_activity_limit_exceeded: 22,
          deployments_limit_exceeded: 23,
          # 24 was previously used by the deprecated `user_blocked`
          project_deleted: 25,
          filtered_by_rules: 26,
          filtered_by_workflow_rules: 27
        }
      end

      def self.persistable_failure_reasons
        failure_reasons.except(:filtered_by_rules, :filtered_by_workflow_rules)
      end

      def self.persistable_failure_reason?(reason)
        persistable_failure_reasons.include?(reason)
      end

      # Returns the `Hash` to use for creating the `sources` enum for
      # `Ci::Pipeline`.
      def self.sources
        {
          unknown: nil,
          push: 1,
          web: 2,
          trigger: 3,
          schedule: 4,
          api: 5,
          external: 6,
          pipeline: 7,
          chat: 8,
          webide: 9,
          merge_request_event: 10,
          external_pull_request_event: 11,
          parent_pipeline: 12,
          ondemand_dast_scan: 13,
          ondemand_dast_validation: 14,
          security_orchestration_policy: 15,
          container_registry_push: 16,
          duo_workflow: 17,
          pipeline_execution_policy_schedule: 18
        }
      end

      # Dangling sources are those events that generate pipelines for which
      # we don't want to directly affect the ref CI status.
      # - when a webide pipeline fails it does not change the ref CI status to failed
      # - when a child pipeline (from parent_pipeline source) fails it affects its
      #   parent pipeline. It's up to the parent to affect the ref CI status
      # - when an ondemand_dast_scan pipeline runs it is for testing purpose and should
      #   not affect the ref CI status.
      # - when an ondemand_dast_validation pipeline runs it is for validating a DAST site
      #   profile and should not affect the ref CI status.
      # - when a container_registry_push pipeline runs it is for security testing purpose and should
      #   not affect the ref CI status.
      def self.dangling_sources
        sources.slice(
          :webide,
          :parent_pipeline,
          :ondemand_dast_scan,
          :ondemand_dast_validation,
          :security_orchestration_policy,
          :container_registry_push,
          :duo_workflow,
          :pipeline_execution_policy_schedule
        )
      end

      # CI sources are those pipeline events that affect the CI status of the ref
      # they run for. By definition it excludes dangling pipelines.
      def self.ci_sources
        sources.except(*dangling_sources.keys)
      end

      def self.ci_branch_sources
        ci_sources.except(:merge_request_event)
      end

      def self.ci_and_parent_sources
        ci_sources.merge(sources.slice(:parent_pipeline))
      end

      def self.ci_and_security_orchestration_sources
        ci_sources.merge(sources.slice(:security_orchestration_policy))
      end

      # Returns the `Hash` to use for creating the `config_sources` enum for
      # `Ci::Pipeline`.
      def self.config_sources
        {
          unknown_source: nil,
          repository_source: 1,
          auto_devops_source: 2,
          webide_source: 3,
          remote_source: 4,
          external_project_source: 5,
          bridge_source: 6,
          parameter_source: 7,
          compliance_source: 8,
          security_policies_default_source: 9,
          pipeline_execution_policy_forced: 10
        }
      end
    end
  end
end
