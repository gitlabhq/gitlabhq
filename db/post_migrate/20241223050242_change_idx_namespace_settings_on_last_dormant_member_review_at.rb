# frozen_string_literal: true

class ChangeIdxNamespaceSettingsOnLastDormantMemberReviewAt < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.8'

  OLD_INDEX_NAME = 'idx_namespace_settings_on_remove_dormant_members_review_at'
  NEW_INDEX_NAME = 'idx_namespace_settings_on_last_dormant_members_review_at'
  TABLE = :namespace_settings

  def up
    add_concurrent_index TABLE,
      :last_dormant_member_review_at,
      where: 'remove_dormant_members = true',
      name: NEW_INDEX_NAME
    remove_concurrent_index_by_name TABLE, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE,
      [:last_dormant_member_review_at, :remove_dormant_members],
      where: 'remove_dormant_members IS true',
      name: OLD_INDEX_NAME
    remove_concurrent_index_by_name TABLE, NEW_INDEX_NAME
  end
end
