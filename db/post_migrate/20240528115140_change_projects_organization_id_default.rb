# frozen_string_literal: true

class ChangeProjectsOrganizationIdDefault < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  enable_lock_retries!

  def up
    change_column_default(:projects, :organization_id, nil)
  end

  def down
    change_column_default(:projects, :organization_id, 1)
  end
end
