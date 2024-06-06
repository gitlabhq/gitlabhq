# frozen_string_literal: true

module Ci
  class UpdateBuildNamesWorker
    include ApplicationWorker

    data_consistency :delayed
    sidekiq_options retry: 3
    feature_category :continuous_integration
    idempotent!
    deduplicate :until_executing

    def perform(pipeline_id)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::UpdateBuildNamesService.new(pipeline).execute
      end
    end
  end
end
