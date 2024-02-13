# frozen_string_literal: true

class CreateIndexMembersOnSourceAndTypeAndId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  INDEX_NAME = 'index_members_on_source_and_type_and_id'

  def up
    # This index was created async previously, check https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142719.
    add_concurrent_index(
      :members, [:source_id, :source_type, :type, :id],
      where: 'invite_token IS NULL',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
