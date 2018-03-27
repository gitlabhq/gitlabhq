# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateEnvironmentScaling < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :environment_scalings do |t|
      t.integer :production_replicas, null: false
      t.references :environment, index: true, foreign_key: { on_delete: :cascade}, null: false
    end
  end
end
