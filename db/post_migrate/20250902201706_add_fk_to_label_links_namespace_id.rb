# frozen_string_literal: true

class AddFkToLabelLinksNamespaceId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_foreign_key :label_links,
      :namespaces,
      column: :namespace_id,
      target_column: :id,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :label_links, column: :namespace_id
    end
  end
end
