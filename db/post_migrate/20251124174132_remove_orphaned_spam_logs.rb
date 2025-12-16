# frozen_string_literal: true

class RemoveOrphanedSpamLogs < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    define_batchable_model(:spam_logs).each_batch(of: 1_000) do |batch|
      batch
        .joins('LEFT OUTER JOIN users ON spam_logs.user_id = users.id')
        .where(users: { id: nil })
        .delete_all
    end
  end

  def down; end
end
