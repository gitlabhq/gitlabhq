# frozen_string_literal: true

class AddProjectTopicUploadStatesOrganizationIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :project_topic_upload_states,
      sharding_key: :organization_id,
      parent_table: :project_topic_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :project_topic_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :project_topic_upload_states,
      sharding_key: :organization_id,
      parent_table: :project_topic_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :project_topic_upload_id
    )
  end
end
