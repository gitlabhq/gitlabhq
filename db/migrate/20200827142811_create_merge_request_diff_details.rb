# frozen_string_literal: true

class CreateMergeRequestDiffDetails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:merge_request_diff_details)
      with_lock_retries do
        create_table :merge_request_diff_details, id: false do |t|
          t.references :merge_request_diff, primary_key: true, null: false, foreign_key: { on_delete: :cascade }
          t.datetime_with_timezone :verification_retry_at
          t.datetime_with_timezone :verified_at
          t.integer :verification_retry_count, limit: 2
          t.binary :verification_checksum, using: 'verification_checksum::bytea'
          t.text :verification_failure
        end
      end
    end

    add_text_limit :merge_request_diff_details, :verification_failure, 255
  end

  def down
    drop_table :merge_request_diff_details
  end
end
