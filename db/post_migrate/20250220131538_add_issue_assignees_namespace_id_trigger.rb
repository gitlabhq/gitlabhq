# frozen_string_literal: true

class AddIssueAssigneesNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :issue_assignees,
      sharding_key: :namespace_id,
      parent_table: :issues,
      parent_sharding_key: :namespace_id,
      foreign_key: :issue_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :issue_assignees,
      sharding_key: :namespace_id,
      parent_table: :issues,
      parent_sharding_key: :namespace_id,
      foreign_key: :issue_id
    )
  end
end
