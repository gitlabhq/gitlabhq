# frozen_string_literal: true

class ChangeDefaultOrganizationIdOnUsers < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  DEFAULT_ORGANIZATION_ID = 1

  def up
    change_column_default(:users, :organization_id, from: DEFAULT_ORGANIZATION_ID, to: nil)
  end

  def down
    change_column_default(:users, :organization_id, from: nil, to: DEFAULT_ORGANIZATION_ID)
  end
end
