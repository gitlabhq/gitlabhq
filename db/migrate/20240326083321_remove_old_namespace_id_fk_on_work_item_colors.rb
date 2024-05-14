# frozen_string_literal: true

class RemoveOldNamespaceIdFkOnWorkItemColors < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  OLD_FK_NAME = 'fk_b15b0912d0'

  # new foreign key added in FixWorkItemColorsCascadeOptionOnFkToNamespaceId
  # and validated in ValidateNewNamespaceIdFkOnWorkItemColors
  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :work_item_colors,
        column: :namespace_id,
        on_delete: :nullify,
        name: OLD_FK_NAME
      )
    end
  end

  def down
    # Validation is skipped here, so if rolled back, this will need to be revalidated in a separate migration
    add_concurrent_foreign_key(
      :work_item_colors,
      :namespaces,
      column: :namespace_id,
      on_delete: :nullify,
      name: OLD_FK_NAME
    )
  end
end
