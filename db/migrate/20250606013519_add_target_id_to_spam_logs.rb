# frozen_string_literal: true

class AddTargetIdToSpamLogs < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :spam_logs, :target_id, :bigint
  end
end
