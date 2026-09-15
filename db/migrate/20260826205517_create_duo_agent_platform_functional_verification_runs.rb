# frozen_string_literal: true

class CreateDuoAgentPlatformFunctionalVerificationRuns < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  # The table name is 48 characters, so auto-generated index names would exceed
  # the 63-character Postgres limit.
  CHECK_TYPE_INDEX = 'idx_dap_functional_verification_runs_on_check_type'
  WORKFLOW_ID_INDEX = 'idx_dap_functional_verification_runs_on_workflow_id'

  def change
    create_table :duo_agent_platform_functional_verification_runs do |t|
      # No DB-level FK: this table is gitlab_main_cell_setting, the workflow is
      # gitlab_main_org, and a cell-setting row must not hold a hard reference
      # to organization-scoped data. Cleaned up via loose foreign keys instead.
      t.bigint :workflow_id

      t.timestamps_with_timezone null: false

      t.integer :check_type, limit: 2, null: false
      # Nullable: a row can exist before its first run records a status.
      t.integer :status, limit: 2

      t.text :message, limit: 1024

      t.index :check_type, unique: true, name: CHECK_TYPE_INDEX
      t.index :workflow_id, unique: true, name: WORKFLOW_ID_INDEX
    end
  end
end
