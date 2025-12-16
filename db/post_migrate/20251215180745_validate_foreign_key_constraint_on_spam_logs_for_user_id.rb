# frozen_string_literal: true

class ValidateForeignKeyConstraintOnSpamLogsForUserId < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def up
    validate_foreign_key :spam_logs, :user_id, name: 'fk_1cb83308b1'
  end

  def down
    # no-op
  end
end
