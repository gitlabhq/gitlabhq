# frozen_string_literal: true

class AddRemoveDormantMembersIdxNamespaceSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  COLUMNS = %i[last_dormant_member_review_at remove_dormant_members]
  INDEX_NAME = 'idx_namespace_settings_on_remove_dormant_members_review_at'
  TABLE = :namespace_settings

  def up
    add_concurrent_index(
      TABLE,
      COLUMNS,
      where: 'remove_dormant_members IS true',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index(
      TABLE,
      COLUMNS,
      name: INDEX_NAME
    )
  end
end
