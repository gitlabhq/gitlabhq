# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Failed < Status::Extended
          # rubocop: disable Layout/LineLength -- Long error messages
          REASONS = {
            unknown_failure: 'unknown failure',
            script_failure: 'script failure',
            api_failure: 'API failure',
            stuck_or_timeout_failure: 'stuck or timeout failure',
            runner_system_failure: 'runner system failure',
            missing_dependency_failure: 'missing dependency failure',
            runner_unsupported: 'unsupported runner',
            stale_schedule: 'stale schedule',
            job_execution_timeout: 'job execution timeout',
            archived_failure: 'archived failure',
            unmet_prerequisites: 'unmet prerequisites',
            scheduler_failure: 'scheduler failure',
            data_integrity_failure: 'data integrity failure',
            forward_deployment_failure: 'forward deployment failure',
            protected_environment_failure: 'protected environment failure',
            pipeline_loop_detected: 'job would create infinitely looping pipelines',
            invalid_bridge_trigger: 'downstream pipeline trigger definition is invalid',
            downstream_bridge_project_not_found: 'downstream project could not be found',
            upstream_bridge_project_not_found: 'upstream project could not be found',
            insufficient_bridge_permissions: 'no permissions to trigger downstream pipeline',
            insufficient_upstream_permissions: 'no permissions to read upstream project',
            bridge_pipeline_is_child_pipeline: 'creation of child pipeline not allowed from another child pipeline',
            downstream_pipeline_creation_failed: 'downstream pipeline can not be created',
            secrets_provider_not_found: 'secrets provider can not be found',
            reached_max_descendant_pipelines_depth: 'reached maximum depth of child pipelines',
            reached_max_pipeline_hierarchy_size: 'downstream pipeline tree is too large',
            project_deleted: 'pipeline project was deleted',
            user_blocked: 'pipeline user was blocked',
            ci_quota_exceeded: 'no more compute minutes available',
            no_matching_runner: 'no matching runner available',
            trace_size_exceeded: 'log size limit exceeded',
            builds_disabled: 'project builds are disabled',
            environment_creation_failure: 'environment creation failure',
            deployment_rejected: 'deployment rejected',
            ip_restriction_failure: 'IP address restriction failure',
            failed_outdated_deployment_job: 'failed outdated deployment job',
            reached_downstream_pipeline_trigger_rate_limit: 'Too many downstream pipelines triggered in the last minute. Try again later.'
          }.freeze
          # rubocop: enable Layout/LineLength

          private_constant :REASONS

          def status_tooltip
            base_message
          end

          def badge_tooltip
            base_message
          end

          def self.matches?(build, user)
            build.failed?
          end

          def self.reasons
            REASONS
          end

          private

          def base_message
            "#{s_('CiStatusLabel|Failed')} #{description}"
          end

          def description
            "- (#{failure_reason_message})"
          end

          def failure_reason_message
            self.class.reasons.fetch(subject.failure_reason.to_sym)
          end
        end
      end
    end
  end
end
