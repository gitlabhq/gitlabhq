# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Limit
          class Size < Chain::Base
            include ::Gitlab::Ci::Pipeline::Chain::Helpers

            def initialize(*)
              super

              @limit = Gitlab::Ci::Pipeline::Quota::Size
                .new(project.namespace, pipeline, command)
            end

            def perform!
              if limit.exceeded?
                limit.log_error!(log_attrs)
                error(limit.message, failure_reason: :size_limit_exceeded)
              elsif limit.log_exceeded_limit?
                limit.log_error!(log_attrs)
              end
            end

            def break?
              limit.exceeded?
            end

            private

            attr_reader :limit

            def log_attrs
              {
                jobs_count: jobs_count,
                pipeline_source: pipeline.source,
                plan: project.actual_plan_name,
                project_id: project.id,
                project_full_path: project.full_path
              }
            end

            # Remove when `ci_refactor_jobs_count_in_alive_pipelines` is removed.
            def jobs_count
              if command.ci_refactor_jobs_count_in_alive_pipelines_enabled?
                command.current_pipeline_size
              else
                pipeline.statuses.count
              end
            end
          end
        end
      end
    end
  end
end
