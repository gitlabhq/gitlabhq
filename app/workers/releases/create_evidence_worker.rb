# frozen_string_literal: true

module Releases
  class CreateEvidenceWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :release_evidence
    tags :exclude_from_kubernetes

    # pipeline_id is optional for backward compatibility with existing jobs
    # caller should always try to provide the pipeline and pass nil only
    # if pipeline is absent
    def perform(release_id, pipeline_id = nil)
      release = Release.find_by_id(release_id)

      return unless release

      pipeline = Ci::Pipeline.find_by_id(pipeline_id)

      ::Releases::CreateEvidenceService.new(release, pipeline: pipeline).execute
    end
  end
end
