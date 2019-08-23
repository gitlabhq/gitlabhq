# frozen_string_literal: true

class AddRepositoriesTable < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :repositories, id: :bigserial do |t|
      t.references :shard, null: false, index: true, foreign_key: { on_delete: :restrict }
      t.string :disk_path, null: false, index: { unique: true } # rubocop:disable Migration/AddLimitToStringColumns
    end

    add_column :projects, :pool_repository_id, :bigint
    add_index :projects, :pool_repository_id, where: 'pool_repository_id IS NOT NULL'
  end
end
