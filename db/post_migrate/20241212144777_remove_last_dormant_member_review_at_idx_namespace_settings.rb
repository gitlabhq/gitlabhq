# frozen_string_literal: true

class RemoveLastDormantMemberReviewAtIdxNamespaceSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.8'

  INDEX_NAME = 'idx_namespace_settings_on_last_dormant_member_review_at'

  def up
    remove_concurrent_index :namespace_settings, :last_dormant_member_review_at, name: INDEX_NAME
  end

  def down
    add_concurrent_index(
      :namespace_settings, :last_dormant_member_review_at,
      where: 'remove_dormant_members IS true',
      name: INDEX_NAME
    )
  end
end
