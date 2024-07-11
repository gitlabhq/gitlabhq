# frozen_string_literal: true

module Ci
  module JobArtifacts
    class ExpireProjectBuildArtifactsWorker
      include ApplicationWorker

      data_consistency :always

      feature_category :job_artifacts
      idempotent!

      def perform(project_id)
        return unless Project.id_in(project_id).exists?

        ExpireProjectBuildArtifactsService.new(project_id, Time.current).execute
      end
    end
  end
end
