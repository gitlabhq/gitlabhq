# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateCiBuildsRunnerSession < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :ci_builds_runner_session, id: :bigserial do |t|
      t.integer :build_id, null: false
      t.string :url, null: false
      t.string :certificate
      t.string :authorization

      t.foreign_key :ci_builds, column: :build_id, on_delete: :cascade
      t.index :build_id, unique: true
    end
  end
  # rubocop:enable Migration/PreventStrings
end
