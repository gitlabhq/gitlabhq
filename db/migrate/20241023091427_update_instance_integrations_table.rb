# frozen_string_literal: true

class UpdateInstanceIntegrationsTable < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    add_column :instance_integrations, :project_id, :bigint, null: true, if_not_exists: true
    add_column :instance_integrations, :group_id, :bigint, null: true, if_not_exists: true
    add_column :instance_integrations, :inherit_from_id, :bigint, null: true, if_not_exists: true
    add_column :instance_integrations, :instance, :boolean, default: true, if_not_exists: true

    add_check_constraint :instance_integrations, 'project_id IS NULL', 'project_id_null_constraint'
    add_check_constraint :instance_integrations, 'group_id IS NULL', 'group_id_null_constraint'
    add_check_constraint :instance_integrations, 'inherit_from_id IS NULL', 'inherit_from_id_null_constraint'
    add_check_constraint :instance_integrations, 'instance = TRUE', 'instance_is_true_constraint'
  end

  def down
    remove_column :instance_integrations, :project_id, if_exists: true
    remove_column :instance_integrations, :group_id, if_exists: true
    remove_column :instance_integrations, :inherit_from_id, if_exists: true
    remove_column :instance_integrations, :instance, if_exists: true
  end
end
