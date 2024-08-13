# frozen_string_literal: true

class AddApprovalsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    install_sharding_key_assignment_trigger(
      table: :approvals,
      sharding_key: :project_id,
      parent_table: :merge_requests,
      parent_sharding_key: :target_project_id,
      foreign_key: :merge_request_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :approvals,
      sharding_key: :project_id,
      parent_table: :merge_requests,
      parent_sharding_key: :target_project_id,
      foreign_key: :merge_request_id
    )
  end
end
