# frozen_string_literal: true

class RemoveShardingKeyCheckConstraintFromCiRunners2 < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  CONSTRAINT_NAME = 'check_sharding_key_id_nullness'

  def up
    remove_check_constraint(:instance_type_ci_runners, CONSTRAINT_NAME)
    remove_check_constraint(:group_type_ci_runners, CONSTRAINT_NAME)
    remove_check_constraint(:project_type_ci_runners, CONSTRAINT_NAME)
  end

  def down
    add_check_constraint(:instance_type_ci_runners, 'sharding_key_id IS NULL', CONSTRAINT_NAME)
    add_check_constraint(:group_type_ci_runners, 'sharding_key_id IS NOT NULL', CONSTRAINT_NAME)
    add_check_constraint(:project_type_ci_runners, 'sharding_key_id IS NOT NULL', CONSTRAINT_NAME)
  end
end
