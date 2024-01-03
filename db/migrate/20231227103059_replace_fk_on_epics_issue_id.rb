# frozen_string_literal: true

class ReplaceFkOnEpicsIssueId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  FK_NAME = :fk_epics_issue_id_with_on_delete_nullify

  def up
    # This will replace the existing fk_893ee302e5
    add_concurrent_foreign_key(:epics, :issues, column: :issue_id, on_delete: :nullify, validate: false, name: FK_NAME)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:epics, column: :issue_id, on_delete: :nullify, name: FK_NAME)
    end
  end
end
