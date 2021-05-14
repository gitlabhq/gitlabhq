# frozen_string_literal: true

class AddBodyToFindingsEvidencesRequest < ActiveRecord::Migration[6.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210510191552_add_limit_to_findings_evidences_request_body.rb
  def change
    add_column :vulnerability_finding_evidence_requests, :body, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
