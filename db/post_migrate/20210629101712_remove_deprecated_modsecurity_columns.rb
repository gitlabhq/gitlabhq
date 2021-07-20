# frozen_string_literal: true

class RemoveDeprecatedModsecurityColumns < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_clusters_applications_ingress_on_modsecurity'

  def up
    remove_column :clusters_applications_ingress, :modsecurity_enabled if column_exists?(:clusters_applications_ingress, :modsecurity_enabled)
    remove_column :clusters_applications_ingress, :modsecurity_mode if column_exists?(:clusters_applications_ingress, :modsecurity_mode)
  end

  def down
    add_column :clusters_applications_ingress, :modsecurity_enabled, :boolean unless column_exists?(:clusters_applications_ingress, :modsecurity_enabled)
    add_column :clusters_applications_ingress, :modsecurity_mode, :smallint, null: false, default: 0 unless column_exists?(:clusters_applications_ingress, :modsecurity_mode)

    add_concurrent_index :clusters_applications_ingress, [:modsecurity_enabled, :modsecurity_mode, :cluster_id], name: INDEX_NAME
  end
end
