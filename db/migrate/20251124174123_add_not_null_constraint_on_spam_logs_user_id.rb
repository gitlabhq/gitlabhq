# frozen_string_literal: true

class AddNotNullConstraintOnSpamLogsUserId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_not_null_constraint :spam_logs, :user_id, validate: false
  end

  def down
    remove_not_null_constraint :spam_logs, :user_id
  end
end
