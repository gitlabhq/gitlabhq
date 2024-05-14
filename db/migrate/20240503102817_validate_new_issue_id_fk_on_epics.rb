# frozen_string_literal: true

class ValidateNewIssueIdFkOnEpics < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  NEW_FK_NAME = 'fk_epics_issue_id_with_on_delete_cascade'

  # foreign key added in FixEpicsCascadeOptionOnFkToIssueId
  def up
    validate_foreign_key(:epics, :issue_id, name: NEW_FK_NAME)
  end

  def down
    # no-op
  end
end
