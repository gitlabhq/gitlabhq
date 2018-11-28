class AddPagesDomainVerifiedAtIndex < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :pages_domains, :verified_at
  end

  def down
    remove_concurrent_index :pages_domains, :verified_at
  end
end
