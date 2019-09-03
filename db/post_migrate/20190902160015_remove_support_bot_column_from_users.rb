# frozen_string_literal: true

class RemoveSupportBotColumnFromUsers < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return unless column_exists?(:users, :support_bot)

    remove_column :users, :support_bot
  end

  def down
    # no-op because the column should not exist in the previous version
  end
end
