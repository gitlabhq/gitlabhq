# frozen_string_literal: true

class AddPersonalSnippetUploadStatesOrganizationIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :personal_snippet_upload_states,
      sharding_key: :organization_id,
      parent_table: :snippet_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :personal_snippet_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :personal_snippet_upload_states,
      sharding_key: :organization_id,
      parent_table: :snippet_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :personal_snippet_upload_id
    )
  end
end
