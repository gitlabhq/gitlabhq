# frozen_string_literal: true

class AddEscalationPolicies < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  UNIQUE_INDEX_NAME = 'index_on_project_id_escalation_policy_name_unique'

  def up
    create_table_with_constraints :incident_management_escalation_policies do |t|
      t.references :project, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.text :name, null: false
      t.text :description, null: true

      t.text_limit :name, 72
      t.text_limit :description, 160
      t.index [:project_id, :name], unique: true, name: UNIQUE_INDEX_NAME
    end
  end

  def down
    drop_table :incident_management_escalation_policies
  end
end
