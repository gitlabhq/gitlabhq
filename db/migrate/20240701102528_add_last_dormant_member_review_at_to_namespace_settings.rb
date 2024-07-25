# frozen_string_literal: true

class AddLastDormantMemberReviewAtToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :namespace_settings, :last_dormant_member_review_at, :datetime_with_timezone, if_not_exists: true
    end

    add_concurrent_index(
      :namespace_settings, :last_dormant_member_review_at,
      where: 'remove_dormant_members IS true',
      name: 'idx_namespace_settings_on_last_dormant_member_review_at'
    )
  end

  def down
    with_lock_retries do
      remove_column :namespace_settings, :last_dormant_member_review_at, if_exists: true
    end
  end
end
