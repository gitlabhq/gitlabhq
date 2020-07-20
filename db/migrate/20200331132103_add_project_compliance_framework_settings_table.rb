# frozen_string_literal: true

class AddProjectComplianceFrameworkSettingsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :project_compliance_framework_settings, id: false do |t|
        t.references :project, primary_key: true, null: false, index: true, foreign_key: { on_delete: :cascade }
        t.integer :framework, null: false, limit: 2
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :project_compliance_framework_settings
    end
  end
end
