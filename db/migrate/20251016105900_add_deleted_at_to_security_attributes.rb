# frozen_string_literal: true

class AddDeletedAtToSecurityAttributes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  INDEX_NAME = 'index_security_attributes_on_namespace_id_where_not_deleted'

  def up
    add_column :security_attributes, :deleted_at, :datetime_with_timezone
    add_concurrent_index :security_attributes, :namespace_id, where: 'deleted_at IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_attributes, INDEX_NAME
    remove_column :security_attributes, :deleted_at
  end
end
