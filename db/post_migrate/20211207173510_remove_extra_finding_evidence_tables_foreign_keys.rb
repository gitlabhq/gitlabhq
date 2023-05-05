# frozen_string_literal: true

class RemoveExtraFindingEvidenceTablesForeignKeys < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key :vulnerability_finding_evidence_assets, :vulnerability_finding_evidences
      remove_foreign_key :vulnerability_finding_evidence_headers, :vulnerability_finding_evidence_requests
      remove_foreign_key :vulnerability_finding_evidence_headers, :vulnerability_finding_evidence_responses
      remove_foreign_key :vulnerability_finding_evidence_requests, :vulnerability_finding_evidences
      remove_foreign_key :vulnerability_finding_evidence_requests, :vulnerability_finding_evidence_supporting_messages
      remove_foreign_key :vulnerability_finding_evidence_responses, :vulnerability_finding_evidences
      remove_foreign_key :vulnerability_finding_evidence_responses, :vulnerability_finding_evidence_supporting_messages
      remove_foreign_key :vulnerability_finding_evidence_sources, :vulnerability_finding_evidences
      remove_foreign_key :vulnerability_finding_evidence_supporting_messages, :vulnerability_finding_evidences
    end
  end

  def down
    with_lock_retries do
      add_foreign_key :vulnerability_finding_evidence_assets, :vulnerability_finding_evidences, on_delete: :cascade
    end

    with_lock_retries do
      add_foreign_key :vulnerability_finding_evidence_headers, :vulnerability_finding_evidence_requests, on_delete: :cascade
    end

    with_lock_retries do
      add_foreign_key :vulnerability_finding_evidence_headers, :vulnerability_finding_evidence_responses, on_delete: :cascade
    end

    with_lock_retries do
      add_foreign_key :vulnerability_finding_evidence_requests, :vulnerability_finding_evidences, on_delete: :cascade
    end

    with_lock_retries do
      add_foreign_key :vulnerability_finding_evidence_requests, :vulnerability_finding_evidence_supporting_messages, on_delete: :cascade
    end

    with_lock_retries do
      add_foreign_key :vulnerability_finding_evidence_responses, :vulnerability_finding_evidences, on_delete: :cascade
    end

    with_lock_retries do
      add_foreign_key :vulnerability_finding_evidence_responses, :vulnerability_finding_evidence_supporting_messages, on_delete: :cascade
    end

    with_lock_retries do
      add_foreign_key :vulnerability_finding_evidence_sources, :vulnerability_finding_evidences, on_delete: :cascade
    end

    with_lock_retries do
      add_foreign_key :vulnerability_finding_evidence_supporting_messages, :vulnerability_finding_evidences, on_delete: :cascade
    end
  end
end
