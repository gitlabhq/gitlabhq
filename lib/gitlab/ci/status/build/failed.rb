# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Failed < Status::Extended
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
            invalid_bridge_trigger: 'downstream pipeline trigger definition is invalid',
            downstream_bridge_project_not_found: 'downstream project could not be found',
            insufficient_bridge_permissions: 'no permissions to trigger downstream pipeline',
            bridge_pipeline_is_child_pipeline: 'creation of child pipeline not allowed from another child pipeline',
            downstream_pipeline_creation_failed: 'downstream pipeline can not be created'
          }.freeze

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
            "#{s_('CiStatusLabel|failed')} #{description}"
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

Gitlab::Ci::Status::Build::Failed.prepend_if_ee('::EE::Gitlab::Ci::Status::Build::Failed')
