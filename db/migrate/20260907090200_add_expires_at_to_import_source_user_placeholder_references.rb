# frozen_string_literal: true

class AddExpiresAtToImportSourceUserPlaceholderReferences < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  TABLE_NAME = :import_source_user_placeholder_references
  COLUMN_NAME = :expires_at

  def up
    add_column TABLE_NAME, COLUMN_NAME, :datetime_with_timezone
  end

  def down
    remove_column TABLE_NAME, COLUMN_NAME
  end
end
