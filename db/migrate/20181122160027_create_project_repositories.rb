# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateProjectRepositories < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_repositories, id: :bigserial do |t|
      t.references :shard, null: false, index: true, foreign_key: { on_delete: :restrict }
      t.string :disk_path, null: false, index: { unique: true } # rubocop:disable Migration/PreventStrings
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
    end
  end
end
