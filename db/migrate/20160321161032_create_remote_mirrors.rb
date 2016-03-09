class CreateRemoteMirrors < ActiveRecord::Migration
  def change
    create_table :remote_mirrors do |t|
      t.references :project, index: true, foreign_key: true
      t.string :url
      t.boolean :enabled, default: true
      t.string :update_status
      t.datetime :last_update_at
      t.datetime :last_successful_update_at
      t.string :last_error

      t.timestamps null: false
    end
  end
end
