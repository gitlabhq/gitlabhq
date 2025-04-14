# frozen_string_literal: true

class AddColumnRequirementStatusIdProjectControlStatus < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  REQUIREMENT_STATUS_INDEX_NAME = 'idx_project_control_compliance_status_on_requirement_status_id'

  def up
    add_column :project_control_compliance_statuses, :requirement_status_id, :bigint, null: true, if_not_exists: true

    unless index_exists?(:project_control_compliance_statuses, :requirement_status_id,
      name: REQUIREMENT_STATUS_INDEX_NAME)
      add_concurrent_index(:project_control_compliance_statuses,
        :requirement_status_id,
        name: REQUIREMENT_STATUS_INDEX_NAME)
    end

    add_concurrent_foreign_key :project_control_compliance_statuses,
      :project_requirement_compliance_statuses,
      column: :requirement_status_id,
      on_delete: :nullify
  end

  def down
    remove_column :project_control_compliance_statuses, :requirement_status_id, if_exists: true
  end
end
