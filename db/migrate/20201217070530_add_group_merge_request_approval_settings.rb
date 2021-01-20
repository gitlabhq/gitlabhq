# frozen_string_literal: true

class AddGroupMergeRequestApprovalSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :group_merge_request_approval_settings, id: false do |t|
        t.timestamps_with_timezone null: false
        t.references :group, references: :namespaces, primary_key: true, default: nil, index: false,
          foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.boolean :allow_author_approval, null: false, default: false
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :group_merge_request_approval_settings
    end
  end
end
