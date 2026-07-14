# frozen_string_literal: true

class AddColumnsToCdDeployments < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    # rollout_environment_id has no foreign key yet: the cd_rollout_environments
    # table is created in a follow-up. The FK is added then.
    add_column :cd_deployments, :rollout_environment_id, :bigint, if_not_exists: true
    add_column :cd_deployments, :service_id, :bigint, if_not_exists: true

    add_concurrent_index :cd_deployments, :service_id
    add_not_null_constraint :cd_deployments, :service_id

    # rollout_id and version_set_entry_id are being removed (drop deferred to a
    # follow-up). Make them nullable here so the model can stop populating them
    # via ignore_column.
    change_column_null :cd_deployments, :rollout_id, true
    change_column_null :cd_deployments, :version_set_entry_id, true
  end

  def down
    change_column_null :cd_deployments, :version_set_entry_id, false
    change_column_null :cd_deployments, :rollout_id, false
    remove_not_null_constraint :cd_deployments, :service_id
    remove_column :cd_deployments, :service_id, if_exists: true
    remove_column :cd_deployments, :rollout_environment_id, if_exists: true
  end
end
