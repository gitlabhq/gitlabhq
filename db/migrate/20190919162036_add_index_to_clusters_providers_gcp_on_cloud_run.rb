# frozen_string_literal: true

class AddIndexToClustersProvidersGcpOnCloudRun < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:cluster_providers_gcp, :cloud_run)
  end

  def down
    remove_concurrent_index(:cluster_providers_gcp, :cloud_run)
  end
end
