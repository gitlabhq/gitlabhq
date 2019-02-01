class AddPagesDomainEnabledUntilIndex < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :pages_domains, [:project_id, :enabled_until]
    add_concurrent_index :pages_domains, [:verified_at, :enabled_until]
  end

  def down
    remove_concurrent_index :pages_domains, [:verified_at, :enabled_until]
    remove_concurrent_index :pages_domains, [:project_id, :enabled_until]
  end
end
