# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateJobVariables < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    # rubocop:disable Migration/AddLimitToStringColumns
    create_table :ci_job_variables do |t|
      t.string :key, null: false
      t.text :encrypted_value
      t.string :encrypted_value_iv
      t.references :job, null: false, index: true, foreign_key: { to_table: :ci_builds, on_delete: :cascade }
      t.integer :variable_type, null: false, limit: 2, default: 1
    end
    # rubocop:enable Migration/AddLimitToStringColumns

    add_index :ci_job_variables, [:key, :job_id], unique: true
  end
end
