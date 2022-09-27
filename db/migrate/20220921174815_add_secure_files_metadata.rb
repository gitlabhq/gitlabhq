# frozen_string_literal: true

class AddSecureFilesMetadata < Gitlab::Database::Migration[2.0]
  def change
    add_column :ci_secure_files, :metadata, :jsonb
    add_column :ci_secure_files, :expires_at, :datetime_with_timezone
  end
end
