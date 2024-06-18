# frozen_string_literal: true

class AddMlExperimentMetadataProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :ml_experiment_metadata,
      sharding_key: :project_id,
      parent_table: :ml_experiments,
      parent_sharding_key: :project_id,
      foreign_key: :experiment_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :ml_experiment_metadata,
      sharding_key: :project_id,
      parent_table: :ml_experiments,
      parent_sharding_key: :project_id,
      foreign_key: :experiment_id
    )
  end
end
