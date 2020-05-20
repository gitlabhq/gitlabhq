# frozen_string_literal: true

class AddIndexOnModsecurityToIngress < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_clusters_applications_ingress_on_modsecurity'

  disable_ddl_transaction!

  def up
    add_concurrent_index :clusters_applications_ingress, [:modsecurity_enabled, :modsecurity_mode, :cluster_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :clusters_applications_ingress, [:modsecurity_enabled, :modsecurity_mode, :cluster_id], name: INDEX_NAME
  end
end
