# frozen_string_literal: true

class AddKeyDataToSecureFiles < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    unless column_exists? :ci_secure_files, :key_data
      add_column :ci_secure_files, :key_data, :text
    end

    add_text_limit :ci_secure_files, :key_data, 128
  end

  def down
    remove_column :ci_secure_files, :key_data
  end
end
