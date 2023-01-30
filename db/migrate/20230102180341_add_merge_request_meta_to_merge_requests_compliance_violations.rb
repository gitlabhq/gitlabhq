# frozen_string_literal: true

class AddMergeRequestMetaToMergeRequestsComplianceViolations < Gitlab::Database::Migration[2.1]
  def change
    add_column :merge_requests_compliance_violations, :merged_at, :datetime_with_timezone
    add_column :merge_requests_compliance_violations, :target_project_id, :integer
    add_column :merge_requests_compliance_violations, :title, :text # rubocop:disable Migration/AddLimitToTextColumns
    add_column :merge_requests_compliance_violations, :target_branch, :text # rubocop:disable Migration/AddLimitToTextColumns
  end
end
