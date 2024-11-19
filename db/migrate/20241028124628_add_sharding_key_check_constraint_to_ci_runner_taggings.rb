# frozen_string_literal: true

class AddShardingKeyCheckConstraintToCiRunnerTaggings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  CONSTRAINT_NAME = 'check_sharding_key_id_nullness'

  def up
    add_check_constraint(:ci_runner_taggings_instance_type, 'sharding_key_id IS NULL', CONSTRAINT_NAME)
    add_check_constraint(:ci_runner_taggings_group_type, 'sharding_key_id IS NOT NULL', CONSTRAINT_NAME)
    add_check_constraint(:ci_runner_taggings_project_type, 'sharding_key_id IS NOT NULL', CONSTRAINT_NAME)
  end

  def down
    remove_check_constraint(:ci_runner_taggings_instance_type, CONSTRAINT_NAME)
    remove_check_constraint(:ci_runner_taggings_group_type, CONSTRAINT_NAME)
    remove_check_constraint(:ci_runner_taggings_project_type, CONSTRAINT_NAME)
  end
end
