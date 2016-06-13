# rubocop:disable all
class CreateProjectGroupLinks < ActiveRecord::Migration
  def change
    create_table :project_group_links do |t|
      t.integer :project_id, null: false
      t.integer :group_id, null: false

      t.timestamps
    end
  end
end
