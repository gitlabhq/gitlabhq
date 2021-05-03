# frozen_string_literal: true

module Releases
  class ManageEvidenceWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :release_evidence
    tags :exclude_from_kubernetes

    def perform
      releases = Release.without_evidence.released_within_2hrs

      releases.each do |release|
        project = release.project
        params = { tag: release.tag }

        evidence_pipeline = Releases::EvidencePipelineFinder.new(project, params).execute

        # perform_at released_at
        ::Releases::CreateEvidenceWorker.perform_async(release.id, evidence_pipeline&.id)
      end
    end
  end
end
