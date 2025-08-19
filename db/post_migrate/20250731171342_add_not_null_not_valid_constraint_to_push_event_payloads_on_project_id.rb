# frozen_string_literal: true

class AddNotNullNotValidConstraintToPushEventPayloadsOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_not_null_constraint :push_event_payloads, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :push_event_payloads, :project_id
  end
end
