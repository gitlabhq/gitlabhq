# frozen_string_literal: true

class AddColumnsToCdRollouts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_column :cd_rollouts, :application_id, :bigint, if_not_exists: true
    add_column :cd_rollouts, :application_flow_definition_id, :bigint, if_not_exists: true
    add_column :cd_rollouts, :workflow_ref, :text, if_not_exists: true

    add_text_limit :cd_rollouts, :workflow_ref, 255

    add_concurrent_index :cd_rollouts, :application_id
    add_concurrent_index :cd_rollouts, :application_flow_definition_id
    add_not_null_constraint :cd_rollouts, :application_id

    # environment_id is being removed (drop deferred to a follow-up). Make it
    # nullable here so the model can stop populating it via ignore_column.
    change_column_null :cd_rollouts, :environment_id, true
  end

  def down
    change_column_null :cd_rollouts, :environment_id, false
    remove_not_null_constraint :cd_rollouts, :application_id
    remove_column :cd_rollouts, :workflow_ref, if_exists: true
    remove_column :cd_rollouts, :application_flow_definition_id, if_exists: true
    remove_column :cd_rollouts, :application_id, if_exists: true
  end
end
