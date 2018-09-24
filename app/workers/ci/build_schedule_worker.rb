# frozen_string_literal: true

module Ci
  class BuildScheduleWorker
    include ApplicationWorker
    include PipelineQueue

    def perform(build_id)
      ::Ci::Build.find_by_id(build_id).try do |build|
        Ci::RunScheduledBuildService
          .new(build.project, build.user).execute(build)
      end
    end
  end
end
