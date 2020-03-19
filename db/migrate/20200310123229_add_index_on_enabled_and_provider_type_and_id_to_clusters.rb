# frozen_string_literal: true

class AddIndexOnEnabledAndProviderTypeAndIdToClusters < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :clusters, [:enabled, :provider_type, :id]
    remove_concurrent_index :clusters, :enabled
  end

  def down
    add_concurrent_index :clusters, :enabled
    remove_concurrent_index :clusters, [:enabled, :provider_type, :id]
  end
end
