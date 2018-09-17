# frozen_string_literal: true

class AddLegacyAbacToClusterProvidersGcp < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:cluster_providers_gcp, :legacy_abac, :boolean, default: true)
  end

  def down
    remove_column(:cluster_providers_gcp, :legacy_abac)
  end
end
