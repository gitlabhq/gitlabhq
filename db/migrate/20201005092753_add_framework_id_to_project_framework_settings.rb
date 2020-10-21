# frozen_string_literal: true

class AddFrameworkIdToProjectFrameworkSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:project_compliance_framework_settings, :framework_id)
      with_lock_retries do
        add_column(:project_compliance_framework_settings, :framework_id, :bigint)
      end
    end

    add_concurrent_index(:project_compliance_framework_settings, :framework_id)

    add_concurrent_foreign_key(
      :project_compliance_framework_settings,
      :compliance_management_frameworks,
      column: :framework_id,
      on_delete: :cascade
    )
  end

  def down
    remove_foreign_key_if_exists(:project_compliance_framework_settings, :compliance_management_frameworks, column: :framework_id)

    with_lock_retries do
      remove_column(:project_compliance_framework_settings, :framework_id)
    end
  end
end
