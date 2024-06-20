# frozen_string_literal: true

class AddIssueLinksNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :issue_links,
      sharding_key: :namespace_id,
      parent_table: :issues,
      parent_sharding_key: :namespace_id,
      foreign_key: :source_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :issue_links,
      sharding_key: :namespace_id,
      parent_table: :issues,
      parent_sharding_key: :namespace_id,
      foreign_key: :source_id
    )
  end
end
