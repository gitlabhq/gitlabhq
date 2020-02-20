# frozen_string_literal: true

class CreateProjectSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :project_settings, id: false do |t|
      t.timestamps_with_timezone null: false
      t.references :project, primary_key: true, default: nil, type: :integer, index: false, foreign_key: { on_delete: :cascade }
    end
  end
end
