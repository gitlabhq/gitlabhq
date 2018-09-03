# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateCiBuildsConfigValues < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_builds_config_values, id: :bigserial do |t|
      t.integer :build_id, null: false
      t.foreign_key :ci_builds, column: :build_id, on_delete: :cascade

      t.integer :key, null: false
      t.integer :index
      t.text :value_string
    end
  end
end
