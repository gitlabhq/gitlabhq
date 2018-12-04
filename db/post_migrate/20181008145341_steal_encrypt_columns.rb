class StealEncryptColumns < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('EncryptColumns')
  end

  def down
    # no-op
  end
end
