# frozen_string_literal: true

class AddProjectUploadStatesProjectIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :project_upload_states,
      sharding_key: :project_id,
      parent_table: :project_uploads,
      parent_sharding_key: :project_id,
      foreign_key: :project_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :project_upload_states,
      sharding_key: :project_id,
      parent_table: :project_uploads,
      parent_sharding_key: :project_id,
      foreign_key: :project_upload_id
    )
  end
end
