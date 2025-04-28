# frozen_string_literal: true

class AddAuthorEmailToSshSignatures < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in a separate migration 20250425111203
  def up
    add_column :ssh_signatures, :author_email, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :ssh_signatures, :author_email if column_exists?(:ssh_signatures, :author_email)
  end
end
