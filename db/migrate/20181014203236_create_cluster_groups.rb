# frozen_string_literal: true

class CreateClusterGroups < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :cluster_groups do |t|
      t.references :cluster, null: false, foreign_key: { on_delete: :cascade }
      t.references :group, null: false, index: true

      t.index [:cluster_id, :group_id], unique: true
      t.foreign_key :namespaces, column: :group_id, on_delete: :cascade
    end
  end
end
