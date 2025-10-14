# frozen_string_literal: true

class AddForeignKeyOnProjectIdToTagX509Signatures < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :tag_x509_signatures, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :tag_x509_signatures, column: :project_id
    end
  end
end
