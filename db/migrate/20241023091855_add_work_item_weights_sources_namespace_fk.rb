# frozen_string_literal: true

class AddWorkItemWeightsSourcesNamespaceFk < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_weights_sources, :namespaces,
      column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :work_item_weights_sources, column: :namespace_id
    end
  end
end
