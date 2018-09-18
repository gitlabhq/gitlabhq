# frozen_string_literal: true

module Ci
  class BuildScheduleWorker
    include ApplicationWorker
    include PipelineQueue

    def perform(build_id)
      ::Ci::Build.preload(:build_schedule).find_by(id: build_id).try do |build|
        break unless build.scheduled?

        build.unschedule!
        Ci::PlayBuildService.new(build.project, build.user).execute(build)
      end
    end
  end
end
