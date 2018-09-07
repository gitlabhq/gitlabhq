# frozen_string_literal: true

module Ci
  class EnqueueBuildWorker
    include ApplicationWorker
    include PipelineQueue

    queue_namespace :pipeline_processing

    def perform(build_id)
      ::Ci::Build.find_by(id: build_id).try do |build|
        build.enqueue
      end
    end
  end
end
