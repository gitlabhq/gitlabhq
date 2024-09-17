# frozen_string_literal: true

class AddReassignmentErrorToImportSourceUser < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction! # For `add_text_limit`

  def up
    with_lock_retries do
      add_column :import_source_users, :reassignment_error, :text, if_not_exists: true
    end

    add_text_limit :import_source_users, :reassignment_error, 255
  end

  def down
    remove_column :import_source_users, :reassignment_error, if_exists: true
  end
end
