# frozen_string_literal: true

class AddCloudRunToClustersProvidersGcp < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:cluster_providers_gcp, :cloud_run, :boolean, default: false) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:cluster_providers_gcp, :cloud_run)
  end
end
