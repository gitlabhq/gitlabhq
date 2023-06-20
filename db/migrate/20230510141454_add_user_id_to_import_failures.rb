# frozen_string_literal: true

class AddUserIdToImportFailures < Gitlab::Database::Migration[2.1]
  def change
    add_column :import_failures, :user_id, :bigint
  end
end
