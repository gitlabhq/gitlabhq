# frozen_string_literal: true

module Mutations
  module Ci
    module Pipeline
      class Destroy < Base
        graphql_name 'PipelineDestroy'

        authorize :destroy_pipeline

        def resolve(id:)
          pipeline = authorized_find!(id: id)
          project = pipeline.project

          return undergoing_refresh_error(project) if project.refreshing_build_artifacts_size?

          result = ::Ci::DestroyPipelineService.new(project, current_user).execute(pipeline)
          {
            success: result.success?,
            errors: result.errors
          }
        end

        private

        def undergoing_refresh_error(project)
          Gitlab::ProjectStatsRefreshConflictsLogger.warn_request_rejected_during_stats_refresh(project.id)

          {
            success: false,
            errors: ['Action temporarily disabled. The project this pipeline belongs to is undergoing stats refresh.']
          }
        end
      end
    end
  end
end
