# frozen_string_literal: true

class AddIssuableSlasNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def up
    install_sharding_key_assignment_trigger(
      table: :issuable_slas,
      sharding_key: :namespace_id,
      parent_table: :issues,
      parent_sharding_key: :namespace_id,
      foreign_key: :issue_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :issuable_slas,
      sharding_key: :namespace_id,
      parent_table: :issues,
      parent_sharding_key: :namespace_id,
      foreign_key: :issue_id
    )
  end
end
