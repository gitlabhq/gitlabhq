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
            if Feature.enabled?(:ci_ref_delete_use_new_unlock_mechanism, project)
              enqueue_pipelines_to_unlock(ci_ref)
            else
              unlock_artifacts(project, user, ci_ref)
            end
          end
        end
      end
    end

    private

    def unlock_artifacts(project, user, ci_ref)
      result = ::Ci::UnlockArtifactsService
        .new(project, user)
        .execute(ci_ref)

      log_extra_metadata_on_done(:unlocked_pipelines, result[:unlocked_pipelines])
      log_extra_metadata_on_done(:unlocked_job_artifacts, result[:unlocked_job_artifacts])
    end

    def enqueue_pipelines_to_unlock(ci_ref)
      result = ::Ci::Refs::EnqueuePipelinesToUnlockService.new.execute(ci_ref)

      log_extra_metadata_on_done(:total_pending_entries, result[:total_pending_entries])
      log_extra_metadata_on_done(:total_new_entries, result[:total_new_entries])
    end
  end
end
