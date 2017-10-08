# rubocop:disable Migration/Timestamps
class CreateContainerRepository < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :container_repositories do |t|
      t.references :project, foreign_key: true, index: true, null: false
      t.string :name, null: false

      t.timestamps null: false
    end

    add_index :container_repositories, [:project_id, :name], unique: true
  end
end
