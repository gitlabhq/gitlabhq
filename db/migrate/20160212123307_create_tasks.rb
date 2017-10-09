# rubocop:disable all
class CreateTasks < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :tasks do |t|
      t.references :user, null: false, index: true
      t.references :project, null: false, index: true
      t.references :target, polymorphic: true, null: false, index: true
      t.integer :author_id, index: true
      t.integer :action, null: false
      t.string :state, null: false, index: true

      t.timestamps null: true
    end
  end
end
