# frozen_string_literal: true

class PrepareAsyncCheckNotNullConstraintOnSpamLogsForUserId < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  CONSTRAINT_NAME = 'check_56d1d910ee'

  def up
    prepare_async_check_constraint_validation :spam_logs, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :spam_logs, name: CONSTRAINT_NAME
  end
end
