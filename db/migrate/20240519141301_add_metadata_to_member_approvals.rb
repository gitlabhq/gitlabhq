# frozen_string_literal: true

class AddMetadataToMemberApprovals < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  enable_lock_retries!

  def change
    add_column :member_approvals, :metadata, :jsonb, default: {}, null: false
  end
end
