# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Limit
          class ActiveJobs < Chain::Base
            include ::Gitlab::Utils::StrongMemoize
            include ::Gitlab::Ci::Pipeline::Chain::Helpers

            LIMIT_NAME = :ci_active_jobs
            MESSAGE = "Project exceeded the allowed number of jobs in active pipelines. Retry later."

            def perform!
              return unless limits.exceeded?(LIMIT_NAME, count_jobs_in_alive_pipelines)

              error(MESSAGE, failure_reason: :job_activity_limit_exceeded)

              Gitlab::AppLogger.info(
                class: self.class.name,
                message: MESSAGE,
                project_id: project.id,
                plan: project.actual_plan_name,
                project_path: project.path,
                jobs_in_alive_pipelines_count: count_jobs_in_alive_pipelines
              )
            end

            def break?
              pipeline.errors.any?
            end

            private

            def namespace
              strong_memoize(:namespace) do
                project.namespace
              end
            end

            def limits
              strong_memoize(:limits) do
                namespace.actual_limits
              end
            end

            def count_jobs_in_alive_pipelines
              strong_memoize(:count_jobs_in_alive_pipelines) do
                if command.ci_refactor_jobs_count_in_alive_pipelines_enabled?
                  command.current_pipeline_size + command.jobs_count_in_alive_pipelines
                else
                  command.pipeline_seed.size + project.all_pipelines.legacy_jobs_count_in_alive_pipelines
                end
              end
            end
          end
        end
      end
    end
  end
end
