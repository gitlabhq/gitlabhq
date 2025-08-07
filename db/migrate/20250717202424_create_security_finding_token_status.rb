# frozen_string_literal: true

class CreateSecurityFindingTokenStatus < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    create_table :security_finding_token_statuses, id: false do |t|
      t.bigint :security_finding_id, primary_key: true, default: nil
      t.bigint :project_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :status, limit: 2, null: false, default: 0

      t.index :project_id, name: 'idx_security_finding_token_on_project_id'
      t.index :created_at, name: 'idx_security_finding_token_on_created_at'
    end
  end

  def down
    drop_table :security_finding_token_statuses, if_exists: true
  end
end
