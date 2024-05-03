# frozen_string_literal: true

class FixEpicsCascadeOptionOnFkToIssueId < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  NEW_FK_NAME = 'fk_epics_issue_id_with_on_delete_cascade'

  def up
    add_concurrent_foreign_key(
      :epics,
      :issues,
      column: :issue_id,
      on_delete: :cascade,
      validate: false,
      name: NEW_FK_NAME
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :epics,
        column: :issue_id,
        on_delete: :cascade,
        name: NEW_FK_NAME
      )
    end
  end
end
