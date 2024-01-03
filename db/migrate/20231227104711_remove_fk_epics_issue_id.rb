# frozen_string_literal: true

class RemoveFkEpicsIssueId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  FK_NAME = :fk_893ee302e5

  # new foreign key added in db/migrate/20231227103059_replace_fk_on_epics_issue_id.rb
  # and validated in db/migrate/20231227104408_validate_fk_epics_issue_id_with_on_delete_nullify.rb
  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:epics, column: :issue_id, on_delete: :cascade, name: FK_NAME)
    end
  end

  def down
    add_concurrent_foreign_key(:epics, :issues, column: :issue_id, on_delete: :cascade, validate: false, name: FK_NAME)
  end
end
