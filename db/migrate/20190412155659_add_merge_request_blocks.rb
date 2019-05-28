# frozen_string_literal: true

class AddMergeRequestBlocks < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :merge_request_blocks, id: :bigserial do |t|
      t.references :blocking_merge_request,
                   index: false, null: false,
                   foreign_key: { to_table: :merge_requests, on_delete: :cascade }

      t.references :blocked_merge_request,
                   index: true, null: false,
                   foreign_key: { to_table: :merge_requests, on_delete: :cascade }

      t.index [:blocking_merge_request_id, :blocked_merge_request_id],
              unique: true,
              name: 'index_mr_blocks_on_blocking_and_blocked_mr_ids'

      t.timestamps_with_timezone
    end
  end
end
