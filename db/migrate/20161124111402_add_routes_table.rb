# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable Migration/Timestamps
class AddRoutesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :routes do |t|
      t.integer :source_id,    null: false
      t.string  :source_type,  null: false
      t.string  :path,         null: false

      t.timestamps
    end
  end
end
