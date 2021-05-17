# frozen_string_literal: true

class AddBodyToFindingsEvidencesResponse < ActiveRecord::Migration[6.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210512183310_add_limit_to_findings_evidences_response_body.rb
  def change
    add_column :vulnerability_finding_evidence_responses, :body, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
