# frozen_string_literal: true

class CreateProjectAliases < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_aliases do |t|
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }, type: :integer
      t.string :name, null: false, index: { unique: true }

      t.timestamps_with_timezone null: false
    end
  end
end
