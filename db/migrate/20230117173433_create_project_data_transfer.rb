# frozen_string_literal: true

class CreateProjectDataTransfer < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :project_data_transfers do |t|
        t.references :project, index: false, null: false
        t.references :namespace, index: true, null: false
        t.bigint :repository_egress, null: false, default: 0
        t.bigint :artifacts_egress, null: false, default: 0
        t.bigint :packages_egress, null: false, default: 0
        t.bigint :registry_egress, null: false, default: 0
        t.date :date, null: false
        t.datetime_with_timezone :created_at, null: false

        t.index [:project_id, :namespace_id, :date], unique: true,
                name: 'index_project_data_transfers_on_project_and_namespace_and_date'
      end
    end

    add_check_constraint :project_data_transfers,
                         "(date = date_trunc('month', date))", 'project_data_transfers_project_year_month_constraint'
  end

  def down
    with_lock_retries do
      drop_table :project_data_transfers
    end
  end
end
