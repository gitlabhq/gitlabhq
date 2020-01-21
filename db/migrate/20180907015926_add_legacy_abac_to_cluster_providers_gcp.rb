# frozen_string_literal: true

class AddLegacyAbacToClusterProvidersGcp < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:cluster_providers_gcp, :legacy_abac, :boolean, default: true) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:cluster_providers_gcp, :legacy_abac)
  end
end
