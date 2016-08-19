class CreateBoards < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :boards do |t|
      t.references :project, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end
  end
end
