class CreateSparkleInvites < ActiveRecord::Migration
  def change
    create_table :sparkle_invites do |t|
      t.belongs_to :users_project
      t.string :token
      t.datetime :expire_at
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :sparkle_invites, :users_project_id
    add_index :sparkle_invites, :token
  end
end
