# frozen_string_literal: true

class AddMlModelMetadataProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :ml_model_metadata,
      sharding_key: :project_id,
      parent_table: :ml_models,
      parent_sharding_key: :project_id,
      foreign_key: :model_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :ml_model_metadata,
      sharding_key: :project_id,
      parent_table: :ml_models,
      parent_sharding_key: :project_id,
      foreign_key: :model_id
    )
  end
end
