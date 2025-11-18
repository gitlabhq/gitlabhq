# frozen_string_literal: true

class AddNotNullConstraintToAbuseEventsOnOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_not_null_constraint(
      :abuse_events,
      :organization_id,
      validate: false
    )
  end

  def down
    remove_not_null_constraint :abuse_events, :organization_id
  end
end
