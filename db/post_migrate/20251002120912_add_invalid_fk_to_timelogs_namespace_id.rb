# frozen_string_literal: true

class AddInvalidFkToTimelogsNamespaceId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_concurrent_foreign_key :timelogs,
      :namespaces,
      column: :namespace_id,
      validate: false,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :timelogs, column: :namespace_id
    end
  end
end
