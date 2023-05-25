# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    # AdvanceStageWorker is a worker used by the BitBucket Server Importer to wait for a
    # number of jobs to complete, without blocking a thread. Once all jobs have
    # been completed this worker will advance the import process to the next
    # stage.
    class AdvanceStageWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker
      include ::Gitlab::Import::AdvanceStage

      data_consistency :delayed

      sidekiq_options dead: false, retry: 3

      feature_category :importers

      loggable_arguments 1, 2

      # The known importer stages and their corresponding Sidekiq workers.
      STAGES = {
        notes: Stage::ImportNotesWorker,
        lfs_objects: Stage::ImportLfsObjectsWorker,
        finish: Stage::FinishImportWorker
      }.freeze

      def find_import_state(project_id)
        ProjectImportState.jid_by(project_id: project_id, status: :started)
      end

      private

      def next_stage_worker(next_stage)
        STAGES.fetch(next_stage.to_sym)
      end
    end
  end
end
