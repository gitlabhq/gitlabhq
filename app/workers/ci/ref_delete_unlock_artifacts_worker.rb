# frozen_string_literal: true

module Ci
  class RefDeleteUnlockArtifactsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include PipelineBackgroundQueue

    idempotent!

    def perform(project_id, user_id, ref_path)
      ::Project.find_by_id(project_id).try do |project|
        ::User.find_by_id(user_id).try do |user|
          project.ci_refs.find_by_ref_path(ref_path).try do |ci_ref|
            results = ::Ci::UnlockArtifactsService
              .new(project, user)
              .execute(ci_ref)

            log_extra_metadata_on_done(:unlocked_pipelines, results[:unlocked_pipelines])
            log_extra_metadata_on_done(:unlocked_job_artifacts, results[:unlocked_job_artifacts])
          end
        end
      end
    end
  end
end
