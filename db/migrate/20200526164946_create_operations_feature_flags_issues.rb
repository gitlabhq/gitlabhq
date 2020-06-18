# frozen_string_literal: true

class CreateOperationsFeatureFlagsIssues < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :operations_feature_flags_issues do |t|
      t.references :feature_flag, index: false, foreign_key: { on_delete: :cascade, to_table: :operations_feature_flags }, null: false
      t.bigint :issue_id, null: false

      t.index [:feature_flag_id, :issue_id], unique: true, name: :index_ops_feature_flags_issues_on_feature_flag_id_and_issue_id
      t.index :issue_id
    end
  end
end
