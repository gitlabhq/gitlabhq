# frozen_string_literal: true

class RemoveCiSecureFilesPermissionsColumn < Gitlab::Database::Migration[2.0]
  def up
    remove_column :ci_secure_files, :permissions
  end

  def down
    add_column :ci_secure_files, :permissions, :integer, null: false, default: 0, limit: 2
  end
end
