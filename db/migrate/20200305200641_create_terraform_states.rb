# frozen_string_literal: true

class CreateTerraformStates < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :terraform_states do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.integer :file_store, limit: 2
      t.string :file, limit: 255
    end
  end
  # rubocop:enable Migration/PreventStrings
end
