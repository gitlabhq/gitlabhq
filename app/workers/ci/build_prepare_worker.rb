# frozen_string_literal: true

module Ci
  class BuildPrepareWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include PipelineQueue

    queue_namespace :pipeline_processing
    feature_category :continuous_integration

    def perform(build_id)
      Ci::Build.find_by_id(build_id).try do |build|
        Ci::PrepareBuildService.new(build).execute
      end
    end
  end
end
