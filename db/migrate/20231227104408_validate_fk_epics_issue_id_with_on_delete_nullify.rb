# frozen_string_literal: true

class ValidateFkEpicsIssueIdWithOnDeleteNullify < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  FK_NAME = :fk_epics_issue_id_with_on_delete_nullify

  # foreign key added in db/migrate/20231227103059_replace_fk_on_epics_issue_id.rb
  def up
    validate_foreign_key(:epics, :issue_id, name: FK_NAME)
  end

  def down
    # no-op
  end
end
