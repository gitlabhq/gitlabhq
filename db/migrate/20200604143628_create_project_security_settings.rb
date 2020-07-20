# frozen_string_literal: true

class CreateProjectSecuritySettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :project_security_settings, id: false do |t|
        t.references :project, primary_key: true, index: false, foreign_key: { on_delete: :cascade }
        t.timestamps_with_timezone

        t.boolean :auto_fix_container_scanning, default: true, null: false
        t.boolean :auto_fix_dast, default: true, null: false
        t.boolean :auto_fix_dependency_scanning, default: true, null: false
        t.boolean :auto_fix_sast, default: true, null: false
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :project_security_settings
    end
  end
end
