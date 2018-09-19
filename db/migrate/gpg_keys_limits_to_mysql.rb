class IncreaseMysqlTextLimitForGpgKeys < ActiveRecord::Migration
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    return unless Gitlab::Database.mysql?

    change_column :gpg_keys, :key, :text, limit: 16.megabytes - 1
  end

  def down
    # no-op
  end
end
