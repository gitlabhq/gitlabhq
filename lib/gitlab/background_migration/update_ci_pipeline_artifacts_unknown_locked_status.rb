# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # The `ci_pipeline_artifacts.locked` column was added in
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97194 to
    # speed up the finding of expired, pipeline artifacts. By default,
    # the value is "unknown" (2), but the correct value should be the
    # value of the associated `ci_pipelines.locked` value.  This class
    # does an UPDATE join to make the values match.
    class UpdateCiPipelineArtifactsUnknownLockedStatus < BatchedMigrationJob
      feature_category :database

      def perform
        connection.exec_query(<<~SQL)
          UPDATE ci_pipeline_artifacts
          SET locked = ci_pipelines.locked
          FROM ci_pipelines
          WHERE ci_pipeline_artifacts.id BETWEEN #{start_id} AND #{end_id}
            AND ci_pipeline_artifacts.locked = 2
            AND ci_pipelines.id = ci_pipeline_artifacts.pipeline_id;
        SQL
      end
    end
  end
end
