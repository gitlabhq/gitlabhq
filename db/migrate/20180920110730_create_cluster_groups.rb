# frozen_string_literal: true

class CreateClusterGroups < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :cluster_groups do |t|
      t.references :cluster, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.references :group, null: false, index: true

      t.index [:cluster_id, :group_id], unique: true
    end

    add_concurrent_foreign_key :cluster_groups, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_without_error(:cluster_groups, column: :group_id)

    drop_table(:cluster_groups)
  end
end
