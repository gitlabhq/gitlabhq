# frozen_string_literal: true

class AddAiVectorizableFileUploadStatesProjectIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    install_sharding_key_assignment_trigger(
      table: :ai_vectorizable_file_upload_states,
      sharding_key: :project_id,
      parent_table: :ai_vectorizable_file_uploads,
      parent_sharding_key: :project_id,
      foreign_key: :ai_vectorizable_file_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :ai_vectorizable_file_upload_states,
      sharding_key: :project_id,
      parent_table: :ai_vectorizable_file_uploads,
      parent_sharding_key: :project_id,
      foreign_key: :ai_vectorizable_file_upload_id
    )
  end
end
