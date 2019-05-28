# frozen_string_literal: true

module Ci
  class BuildPrepareWorker
    include ApplicationWorker
    include PipelineQueue

    queue_namespace :pipeline_processing

    def perform(build_id)
      Ci::Build.find_by_id(build_id).try do |build|
        Ci::PrepareBuildService.new(build).execute
      end
    end
  end
end
