# frozen_string_literal: true

class RemoveUltraauthProviderFromIdentities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :identities, :provider
    execute "DELETE FROM identities WHERE provider = 'ultraauth'"
    remove_concurrent_index :identities, :provider
  end

  def down
  end
end
