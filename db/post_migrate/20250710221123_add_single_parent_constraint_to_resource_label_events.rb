# frozen_string_literal: true

class AddSingleParentConstraintToResourceLabelEvents < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_multi_column_not_null_constraint(
      :resource_label_events,
      :issue_id, :merge_request_id,
      :epic_id,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(:resource_label_events, :issue_id, :merge_request_id, :epic_id)
  end
end
