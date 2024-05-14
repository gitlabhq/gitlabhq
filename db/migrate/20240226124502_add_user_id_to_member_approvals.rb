# frozen_string_literal: true

class AddUserIdToMemberApprovals < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  def up
    # rubocop:disable Rails/NotNullColumn -- UserId needs to be not null and cant have a default value
    add_column :member_approvals, :user_id, :bigint, null: false
    # rubocop:enable Rails/NotNullColumn

    add_concurrent_index :member_approvals, :user_id
  end

  def down
    remove_column :member_approvals, :user_id
  end
end
