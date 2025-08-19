# frozen_string_literal: true

class AddLabelsOrganizationIdFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_concurrent_foreign_key :labels,
      :organizations,
      column: :organization_id,
      target_column: :id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :labels, column: :organization_id
    end
  end
end
