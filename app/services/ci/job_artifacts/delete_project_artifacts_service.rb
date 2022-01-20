# frozen_string_literal: true

module Ci
  module JobArtifacts
    class DeleteProjectArtifactsService < BaseProjectService
      def execute
        ExpireProjectBuildArtifactsWorker.perform_async(project.id)
      end
    end
  end
end
