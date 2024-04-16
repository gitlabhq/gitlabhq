# frozen_string_literal: true

class RemoveOldNamespaceIdFkOnWorkItemDatesSources < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  OLD_FK_NAME = 'fk_d602f0955d'

  # new foreign key added in FixWorkItemSourceDatesCascadeOptionOnFkToNamespaceId
  # and validated in ValidateNewNamespaceIdFkOnWorkItemDatesSources
  def up
    remove_foreign_key_if_exists(
      :work_item_dates_sources,
      column: :namespace_id,
      on_delete: :nullify,
      name: OLD_FK_NAME
    )
  end

  def down
    # Validation is skipped here, so if rolled back, this will need to be revalidated in a separate migration
    add_concurrent_foreign_key(
      :work_item_dates_sources,
      :namespaces,
      column: :namespace_id,
      on_delete: :nullify,
      validate: false,
      name: OLD_FK_NAME
    )
  end
end
