# frozen_string_literal: true

class AddReportTypeToApprovalMergeRequestRules < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_table :approval_merge_request_rules do |t|
      t.integer :report_type, limit: 2
    end
  end
end
