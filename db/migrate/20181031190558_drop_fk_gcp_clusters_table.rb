# frozen_string_literal: true

class DropFkGcpClustersTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_foreign_key_if_exists :gcp_clusters, column: :project_id
    remove_foreign_key_if_exists :gcp_clusters, column: :user_id
    remove_foreign_key_if_exists :gcp_clusters, column: :service_id
  end

  def down
    add_foreign_key_if_not_exists :gcp_clusters, :projects, column: :project_id, on_delete: :cascade
    add_foreign_key_if_not_exists :gcp_clusters, :users, column: :user_id, on_delete: :nullify
    add_foreign_key_if_not_exists :gcp_clusters, :services, column: :service_id, on_delete: :nullify
  end

  private

  def add_foreign_key_if_not_exists(source, target, column:, on_delete:)
    return unless table_exists?(source)
    return if foreign_key_exists?(source, target, column: column)

    add_concurrent_foreign_key(source, target, column: column, on_delete: on_delete)
  end

  def remove_foreign_key_if_exists(table, column:)
    return unless table_exists?(table)
    return unless foreign_key_exists?(table, column: column)

    remove_foreign_key(table, column: column)
  end
end
