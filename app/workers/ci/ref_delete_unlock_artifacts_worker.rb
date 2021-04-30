# frozen_string_literal: true

module Ci
  class RefDeleteUnlockArtifactsWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include PipelineBackgroundQueue

    idempotent!

    def perform(project_id, user_id, ref_path)
      ::Project.find_by_id(project_id).try do |project|
        ::User.find_by_id(user_id).try do |user|
          project.ci_refs.find_by_ref_path(ref_path).try do |ci_ref|
            ::Ci::UnlockArtifactsService
              .new(project, user)
              .execute(ci_ref)
          end
        end
      end
    end
  end
end
