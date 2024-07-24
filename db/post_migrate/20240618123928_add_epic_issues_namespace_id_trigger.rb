# frozen_string_literal: true

class AddEpicIssuesNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    install_sharding_key_assignment_trigger(
      table: :epic_issues,
      sharding_key: :namespace_id,
      parent_table: :issues,
      parent_sharding_key: :namespace_id,
      foreign_key: :issue_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :epic_issues,
      sharding_key: :namespace_id,
      parent_table: :issues,
      parent_sharding_key: :namespace_id,
      foreign_key: :issue_id
    )
  end
end
