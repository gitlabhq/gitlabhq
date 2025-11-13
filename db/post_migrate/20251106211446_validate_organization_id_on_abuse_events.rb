# frozen_string_literal: true

class ValidateOrganizationIdOnAbuseEvents < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    validate_not_null_constraint :abuse_events, :organization_id
  end

  def down; end
end
