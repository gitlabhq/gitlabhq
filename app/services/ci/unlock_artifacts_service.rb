# frozen_string_literal: true

module Ci
  class UnlockArtifactsService < ::BaseService
    BATCH_SIZE = 100

    def execute(ci_ref, before_pipeline = nil)
      query = <<~SQL.squish
        UPDATE "ci_pipelines"
        SET    "locked" = #{::Ci::Pipeline.lockeds[:unlocked]}
        WHERE  "ci_pipelines"."id" in (
            #{collect_pipelines(ci_ref, before_pipeline).select(:id).to_sql}
            LIMIT  #{BATCH_SIZE}
            FOR  UPDATE SKIP LOCKED
        )
        RETURNING "ci_pipelines"."id";
      SQL

      loop do
        break if Ci::Pipeline.connection.exec_query(query).empty?
      end
    end

    private

    def collect_pipelines(ci_ref, before_pipeline)
      pipeline_scope = ci_ref.pipelines
      pipeline_scope = pipeline_scope.before_pipeline(before_pipeline) if before_pipeline

      pipeline_scope.artifacts_locked
    end
  end
end
