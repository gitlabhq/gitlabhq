# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateUserContribution < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :user_contributions, id: false do |t|
      t.date :date, null: false
      t.references :user, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.integer :contributions, null: false
      t.index [:user_id, :date], unique: true
    end
  end
end
