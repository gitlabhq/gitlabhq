# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Limit
          class RateLimit < Chain::Base
            include Chain::Helpers
            include ::Gitlab::Utils::StrongMemoize

            def perform!
              # We exclude child-pipelines from the rate limit because they represent
              # sub-pipelines, as well as execution policy pipelines
              # that would otherwise hit the rate limit due to having the same scope (project, user, sha).
              #
              return if pipeline.parent_pipeline? || command.pipeline_policy_context&.creating_policy_pipeline?

              if rate_limit_throttled?
                create_log_entry
                error(throttle_message) if enforce_throttle?
              end
            end

            def break?
              @pipeline.errors.any?
            end

            private

            def rate_limit_throttled?
              ::Gitlab::ApplicationRateLimiter.throttled?(
                :pipelines_create, scope: [project, current_user, command.sha]
              )
            end

            def create_log_entry
              Gitlab::AppJsonLogger.info(
                class: self.class.name,
                namespace_id: project.namespace_id,
                project_id: project.id,
                commit_sha: command.sha,
                current_user_id: current_user.id,
                subscription_plan: project.actual_plan_name,
                message: 'Activated pipeline creation rate limit',
                throttled: enforce_throttle?,
                throttle_override: throttle_override?
              )
            end

            def throttle_message
              'Too many pipelines created in the last minute. Try again later.'
            end

            def enforce_throttle?
              strong_memoize(:enforce_throttle) do
                ::Feature.enabled?(:ci_enforce_throttle_pipelines_creation, project) &&
                  !throttle_override?
              end
            end

            def throttle_override?
              strong_memoize(:throttle_override) do
                ::Feature.enabled?(:ci_enforce_throttle_pipelines_creation_override, project)
              end
            end
          end
        end
      end
    end
  end
end
