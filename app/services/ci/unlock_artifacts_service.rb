# frozen_string_literal: true

module Ci
  class UnlockArtifactsService < ::BaseService
    BATCH_SIZE = 100

    def execute(ci_ref, before_pipeline = nil)
      results = {
        unlocked_pipelines: 0,
        unlocked_job_artifacts: 0,
        unlocked_pipeline_artifacts: 0
      }

      loop do
        unlocked_pipelines = []
        unlocked_job_artifacts = []

        ::Ci::Pipeline.transaction do
          unlocked_pipelines = unlock_pipelines(ci_ref, before_pipeline)
          unlocked_job_artifacts = unlock_job_artifacts(unlocked_pipelines)

          results[:unlocked_pipeline_artifacts] += unlock_pipeline_artifacts(unlocked_pipelines)
        end

        break if unlocked_pipelines.empty?

        results[:unlocked_pipelines] += unlocked_pipelines.length
        results[:unlocked_job_artifacts] += unlocked_job_artifacts.length
      end

      results
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def unlock_job_artifacts_query(pipeline_ids)
      ci_job_artifacts = ::Ci::JobArtifact.arel_table

      build_ids = ::Ci::Build.select(:id).where(commit_id: pipeline_ids)

      returning = Arel::Nodes::Grouping.new(ci_job_artifacts[:id])

      Arel::UpdateManager.new
        .table(ci_job_artifacts)
        .where(ci_job_artifacts[:job_id].in(Arel.sql(build_ids.to_sql)))
        .set([[ci_job_artifacts[:locked], ::Ci::JobArtifact.lockeds[:unlocked]]])
        .to_sql + " RETURNING #{returning.to_sql}"
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def unlock_pipelines_query(ci_ref, before_pipeline)
      ci_pipelines = ::Ci::Pipeline.arel_table

      pipelines_scope = ci_ref.pipelines.artifacts_locked
      pipelines_scope = pipelines_scope.before_pipeline(before_pipeline) if before_pipeline
      pipelines_scope = pipelines_scope.select(:id).limit(BATCH_SIZE).lock('FOR UPDATE SKIP LOCKED')

      returning = Arel::Nodes::Grouping.new(ci_pipelines[:id])

      Arel::UpdateManager.new
        .table(ci_pipelines)
        .where(ci_pipelines[:id].in(Arel.sql(pipelines_scope.to_sql)))
        .set([[ci_pipelines[:locked], ::Ci::Pipeline.lockeds[:unlocked]]])
        .to_sql + " RETURNING #{returning.to_sql}"
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    def unlock_job_artifacts(pipelines)
      return if pipelines.empty?

      ::Ci::JobArtifact.connection.exec_query(
        unlock_job_artifacts_query(pipelines.rows.flatten)
      )
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def unlock_pipeline_artifacts(pipelines)
      return 0 if pipelines.empty?

      ::Ci::PipelineArtifact.where(pipeline_id: pipelines.rows.flatten).update_all(locked: :unlocked)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def unlock_pipelines(ci_ref, before_pipeline)
      ::Ci::Pipeline.connection.exec_query(unlock_pipelines_query(ci_ref, before_pipeline))
    end
  end
end
