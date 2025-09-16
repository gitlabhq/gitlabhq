# frozen_string_literal: true

class AddMultiParentConstraintOnNotes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    # no-op
    # Removing this constraint as it caused an incident
    # https://app.incident.io/gitlab/incidents/3974
  end

  def down
    # no-op
  end
end
