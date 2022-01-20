# frozen_string_literal: true

class RemoveExtraFindingEvidenceTables < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      drop_table :vulnerability_finding_evidence_assets, if_exists: true
      drop_table :vulnerability_finding_evidence_headers, if_exists: true
      drop_table :vulnerability_finding_evidence_requests, if_exists: true
      drop_table :vulnerability_finding_evidence_responses, if_exists: true
      drop_table :vulnerability_finding_evidence_sources, if_exists: true
      drop_table :vulnerability_finding_evidence_supporting_messages, if_exists: true
    end
  end

  def down
    create_table :vulnerability_finding_evidence_assets, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.references :vulnerability_finding_evidence, index: { name: 'finding_evidence_assets_on_finding_evidence_id' }, null: false
      t.text :type, limit: 2048
      t.text :name, limit: 2048
      t.text :url, limit: 2048
    end

    create_table :vulnerability_finding_evidence_sources, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.references :vulnerability_finding_evidence, index: { name: 'finding_evidence_sources_on_finding_evidence_id' }, null: false
      t.text :name, limit: 2048
      t.text :url, limit: 2048
    end

    create_table :vulnerability_finding_evidence_supporting_messages, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.references :vulnerability_finding_evidence, index: { name: 'finding_evidence_supporting_messages_on_finding_evidence_id' }, null: false
      t.text :name, limit: 2048
    end

    create_table :vulnerability_finding_evidence_requests, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.references :vulnerability_finding_evidence, index: { name: 'finding_evidence_requests_on_finding_evidence_id' }, null: true
      t.text :method, limit: 32
      t.text :url, limit: 2048
      t.text :body, limit: 2048
      t.references :vulnerability_finding_evidence_supporting_message, index: { name: 'finding_evidence_requests_on_supporting_evidence_id' }, null: true
    end

    create_table :vulnerability_finding_evidence_responses, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.references :vulnerability_finding_evidence, index: { name: 'finding_evidence_responses_on_finding_evidences_id' }, null: true
      t.integer :status_code
      t.text :reason_phrase, limit: 2048
      t.text :body, limit: 2048
      t.references :vulnerability_finding_evidence_supporting_message, index: { name: 'finding_evidence_responses_on_supporting_evidence_id' }, null: true
    end

    create_table :vulnerability_finding_evidence_headers, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.references :vulnerability_finding_evidence_request, index: { name: 'finding_evidence_header_on_finding_evidence_request_id' }, null: true
      t.references :vulnerability_finding_evidence_response, index: { name: 'finding_evidence_header_on_finding_evidence_response_id' }, null: true
      t.text :name, null: false, limit: 255
      t.text :value, null: false, limit: 8192
    end
  end
end
