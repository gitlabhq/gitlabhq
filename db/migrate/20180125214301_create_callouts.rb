# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateCallouts < ActiveRecord::Migration
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :callouts do |t|
      t.string :feature_name, null: false
      t.references :user, index: true, foreign_key: { on_delete: :cascade }, null: false
    end

    add_index :callouts, [:user_id, :feature_name], unique: true
  end
end
