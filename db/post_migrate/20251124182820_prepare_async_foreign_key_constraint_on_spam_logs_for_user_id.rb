# frozen_string_literal: true

class PrepareAsyncForeignKeyConstraintOnSpamLogsForUserId < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  FK_NAME = :fk_1cb83308b1

  def up
    prepare_async_foreign_key_validation :spam_logs, :user_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :spam_logs, :user_id, name: FK_NAME
  end
end
