# frozen_string_literal: true

class CreateSecretsManagerNamespaceEnrollments < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  TABLE_NAME = :secrets_manager_namespace_enrollments
  NAMESPACE_INDEX_NAME = 'uniq_idx_sm_namespace_enrollments_on_namespace_id'

  def up
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.references :namespace,
        foreign_key: { to_table: :namespaces, on_delete: :cascade },
        null: false,
        index: { unique: true, name: NAMESPACE_INDEX_NAME }
      t.timestamps_with_timezone null: false
    end
  end

  def down
    drop_table TABLE_NAME
  end
end
