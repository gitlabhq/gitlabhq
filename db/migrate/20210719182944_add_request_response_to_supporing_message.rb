# frozen_string_literal: true

class AddRequestResponseToSupporingMessage < ActiveRecord::Migration[6.1]
  def change
    change_column_null(:vulnerability_finding_evidence_requests, :vulnerability_finding_evidence_id, true)
    change_column_null(:vulnerability_finding_evidence_responses, :vulnerability_finding_evidence_id, true)

    # rubocop: disable Migration/AddReference
    # Table is empty, so no need to use add_concurrent_foreign_key and add_concurrent_index
    add_reference(:vulnerability_finding_evidence_requests,
                  :vulnerability_finding_evidence_supporting_message,
                  index: { name: 'finding_evidence_requests_on_supporting_evidence_id' },
                  foreign_key: { on_delete: :cascade })
    add_reference(:vulnerability_finding_evidence_responses,
                  :vulnerability_finding_evidence_supporting_message,
                  index: { name: 'finding_evidence_responses_on_supporting_evidence_id' },
                  foreign_key: { on_delete: :cascade })
    # rubocop:enable Migration/AddReference
  end
end
