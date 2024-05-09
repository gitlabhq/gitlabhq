# frozen_string_literal: true

class RemoveOldIssueIdOnEpics < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  OLD_FK_NAME = 'fk_epics_issue_id_with_on_delete_nullify'

  # new foreign key added in FixEpicsCascadeOptionOnFkToIssueId
  # and validated in FixEpicsCascadeOptionOnFkToIssueId
  def up
    remove_foreign_key_if_exists(
      :epics,
      :issues,
      column: :issue_id,
      on_delete: :nullify,
      name: OLD_FK_NAME,
      reverse_lock_order: true
    )
  end

  def down
    # Validation is skipped here, so if rolled back, this will need to be revalidated in a separate migration
    add_concurrent_foreign_key(
      :epics,
      :issues,
      column: :issue_id,
      on_delete: :nullify,
      name: OLD_FK_NAME,
      reverse_lock_order: true
    )
  end
end
