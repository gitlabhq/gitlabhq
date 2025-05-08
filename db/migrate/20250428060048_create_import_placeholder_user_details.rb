# frozen_string_literal: true

class CreateImportPlaceholderUserDetails < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def change
    create_table :import_placeholder_user_details do |t|
      t.bigint :placeholder_user_id, null: false
      t.bigint :namespace_id
      t.integer :deletion_attempts, null: false, default: 0
      t.bigint :organization_id, null: false
      t.datetime_with_timezone :last_deletion_attempt_at
      t.timestamps_with_timezone null: false
    end
  end
end
