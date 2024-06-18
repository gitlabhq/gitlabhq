# frozen_string_literal: true

class ChangePrimaryKeyOfProjectComplianceFrameworkSettings < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    execute <<~SQL
      ALTER TABLE project_compliance_framework_settings DROP CONSTRAINT IF EXISTS project_compliance_framework_settings_pkey
    SQL

    add_column :project_compliance_framework_settings, :id, :primary_key, if_not_exists: true
  end

  def down
    with_lock_retries do
      remove_column :project_compliance_framework_settings, :id, if_exists: true
    end

    execute <<~SQL
      ALTER TABLE project_compliance_framework_settings ADD PRIMARY KEY (project_id)
    SQL
  end
end
