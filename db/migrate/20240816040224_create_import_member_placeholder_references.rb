# frozen_string_literal: true

class CreateImportMemberPlaceholderReferences < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '17.4'

  def change
    create_table :import_placeholder_memberships do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is called import_placeholder_membership
      t.references :source_user,
        index: true,
        null: false,
        foreign_key: { to_table: :import_source_users, on_delete: :cascade }
      t.bigint :namespace_id, null: false, index: true
      t.bigint :group_id, null: true, index: true
      t.bigint :project_id, null: true, index: true
      t.datetime_with_timezone :created_at, null: false
      t.date :expires_at, null: true
      t.integer :access_level, null: false, limit: 2
    end
  end
end
