# frozen_string_literal: true

module Releases
  class ManageEvidenceWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :sticky
    feature_category :release_evidence

    TIMEOUT_EXCEPTIONS = [ActiveRecord::StatementTimeout, ActiveRecord::ConnectionTimeoutError,
      ActiveRecord::AdapterTimeout, ActiveRecord::LockWaitTimeout,
      ActiveRecord::QueryCanceled].freeze

    def perform
      releases = Release.without_evidence.released_within_2hrs

      releases.each do |release|
        process_release(release)
      rescue *TIMEOUT_EXCEPTIONS, StandardError => e
        Gitlab::ErrorTracking.track_exception(
          e,
          release_id: release.id,
          project_id: release.project_id
        )
        next
      end
    end

    private

    def process_release(release)
      return unless release.project

      evidence_pipeline = Releases::EvidencePipelineFinder.new(release.project, tag: release.tag).execute

      # perform_at released_at
      ::Releases::CreateEvidenceWorker.perform_async(release.id, evidence_pipeline&.id)
    end
  end
end
