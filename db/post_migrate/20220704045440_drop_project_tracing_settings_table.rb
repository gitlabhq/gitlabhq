# frozen_string_literal: true

class DropProjectTracingSettingsTable < Gitlab::Database::Migration[2.0]
  def up
    drop_table :project_tracing_settings
  end

  def down
    create_table :project_tracing_settings, id: :bigserial do |t|
      t.timestamps_with_timezone null: false

      t.references :project, type: :integer, null: false, index: { unique: true }

      t.string :external_url, null: false
    end
  end
end
