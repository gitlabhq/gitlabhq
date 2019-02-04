# frozen_string_literal: true

module Ci
  class BuildScheduleWorker
    include ApplicationWorker
    include PipelineQueue

    queue_namespace :pipeline_processing

    def perform(build_id)
      ::Ci::Build.find_by_id(build_id).try do |build|
        break unless build.scheduled?

        Ci::RunScheduledBuildService
          .new(build.project, build.user).execute(build)
      end
    end
  end
end
