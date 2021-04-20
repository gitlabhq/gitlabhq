# frozen_string_literal: true

class AddUserIndexOnSpamLogs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_spam_logs_on_user_id'

  def up
    add_concurrent_index :spam_logs, :user_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :spam_logs, INDEX_NAME
  end
end
