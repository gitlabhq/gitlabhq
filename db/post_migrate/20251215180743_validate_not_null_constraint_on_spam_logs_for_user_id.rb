# frozen_string_literal: true

class ValidateNotNullConstraintOnSpamLogsForUserId < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def up
    validate_not_null_constraint :spam_logs, :user_id, constraint_name: "check_56d1d910ee"
  end

  def down
    # no-op
  end
end
