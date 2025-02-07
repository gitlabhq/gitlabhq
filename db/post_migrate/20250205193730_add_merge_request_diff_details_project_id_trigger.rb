# frozen_string_literal: true

class AddMergeRequestDiffDetailsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    install_sharding_key_assignment_trigger(
      table: :merge_request_diff_details,
      sharding_key: :project_id,
      parent_table: :merge_request_diffs,
      parent_sharding_key: :project_id,
      foreign_key: :merge_request_diff_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :merge_request_diff_details,
      sharding_key: :project_id,
      parent_table: :merge_request_diffs,
      parent_sharding_key: :project_id,
      foreign_key: :merge_request_diff_id
    )
  end
end
