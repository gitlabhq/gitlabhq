# frozen_string_literal: true

module Gitlab
  module JiraImport
    class AdvanceStageWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      sidekiq_options retry: 3
      include QueueOptions
      include ::Gitlab::Import::AdvanceStage

      # The known importer stages and their corresponding Sidekiq workers.
      STAGES = {
        labels: Gitlab::JiraImport::Stage::ImportLabelsWorker,
        issues: Gitlab::JiraImport::Stage::ImportIssuesWorker,
        attachments: Gitlab::JiraImport::Stage::ImportAttachmentsWorker,
        notes: Gitlab::JiraImport::Stage::ImportNotesWorker,
        finish: Gitlab::JiraImport::Stage::FinishImportWorker
      }.freeze

      def find_import_state(project_id)
        JiraImportState.jid_by(project_id: project_id, status: :started)
      end

      private

      def next_stage_worker(next_stage)
        STAGES.fetch(next_stage.to_sym)
      end
    end
  end
end
