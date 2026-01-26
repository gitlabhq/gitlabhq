# frozen_string_literal: true

class AddNotNullToSpamLogsOnOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  def up
    add_not_null_constraint :spam_logs, :organization_id, validate: false
  end

  def down
    remove_not_null_constraint :spam_logs, :organization_id
  end
end
