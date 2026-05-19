# frozen_string_literal: true

class ValidateSpamLogsOrganizationIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  CONSTRAINT_NAME = 'check_0c0873a24a'

  def up
    validate_not_null_constraint :spam_logs, :organization_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
