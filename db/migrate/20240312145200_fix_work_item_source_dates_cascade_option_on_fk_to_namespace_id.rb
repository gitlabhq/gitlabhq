# frozen_string_literal: true

class FixWorkItemSourceDatesCascadeOptionOnFkToNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  NEW_FK_NAME = 'fk_work_item_dates_sources_on_namespace_id'

  def up
    add_concurrent_foreign_key(
      :work_item_dates_sources,
      :namespaces,
      column: :namespace_id,
      on_delete: :cascade,
      validate: false,
      name: NEW_FK_NAME
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :work_item_dates_sources,
        column: :namespace_id,
        on_delete: :cascade,
        name: NEW_FK_NAME
      )
    end
  end
end
