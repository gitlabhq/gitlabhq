# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Limit
          class RateLimit < Chain::Base
            include Chain::Helpers
            include ::Gitlab::Utils::StrongMemoize

            RATE_LIMITS = [
              { key: :pipelines_create, scope: ->(chain) { [chain.project, chain.current_user, chain.command.sha] } },
              { key: :pipelines_created_per_user, scope: ->(chain) { chain.current_user } }
            ].freeze

            EXCLUDED_WORKFLOW_DEFINITIONS = [
              'sast_fp_detection/v1',
              'resolve_sast_vulnerability/v1'
            ].freeze

            def perform!
              # We exclude child-pipelines from the rate limit because they represent
              # sub-pipelines, as well as execution policy pipelines
              # that would otherwise hit the rate limit due to having the same scope (project, user, sha).
              # We also exclude specific duo workflow definitions (e.g., sast_fp_detection/v1)
              # to prevent rate limiting when processing multiple vulnerabilities concurrently.
              # when processing multiple vulnerabilities concurrently.
              return if excluded_from_rate_limit?

              throttled_keys = find_throttled_keys

              if throttled_keys.any?
                create_log_entry(throttled_keys)
                error(throttle_message) if enforce_throttle?
              end
            end

            def break?
              @pipeline.errors.any?
            end

            private

            def excluded_from_rate_limit?
              pipeline.parent_pipeline? ||
                creating_policy_pipeline? ||
                excluded_duo_workflow?
            end

            def creating_policy_pipeline?
              command.pipeline_policy_context&.pipeline_execution_context&.creating_policy_pipeline?
            end

            def excluded_duo_workflow?
              return false unless pipeline.duo_workflow?

              EXCLUDED_WORKFLOW_DEFINITIONS.include?(command.duo_workflow_definition)
            end

            def find_throttled_keys
              RATE_LIMITS.filter_map do |limit|
                scope = limit[:scope].call(self)
                limit[:key] if ::Gitlab::ApplicationRateLimiter.throttled?(limit[:key], scope: scope)
              end
            end

            def create_log_entry(throttled_keys)
              Gitlab::AppJsonLogger.info(
                class: self.class.name,
                namespace_id: project.namespace_id,
                project_id: project.id,
                commit_sha: command.sha,
                subscription_plan: project.actual_plan_name,
                message: "Pipeline rate limit exceeded for #{throttled_keys.to_sentence}",
                throttled: enforce_throttle?,
                throttle_override: throttle_override?
              )
            end

            def throttle_message
              'Too many pipelines created in the last minute. Try again later.'
            end

            def enforce_throttle?
              strong_memoize(:enforce_throttle) do
                !throttle_override?
              end
            end

            def throttle_override?
              strong_memoize(:throttle_override) do
                ::Feature.enabled?(:ci_enforce_throttle_pipelines_creation_override, project, type: :ops)
              end
            end
          end
        end
      end
    end
  end
end
