# frozen_string_literal: true

class TriggerTokenExpireTime < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    add_column :ci_triggers, :expires_at, :datetime_with_timezone
  end

  def down
    remove_column :ci_triggers, :expires_at, :datetime_with_timezone
  end
end
