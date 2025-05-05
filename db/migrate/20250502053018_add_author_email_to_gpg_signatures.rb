# frozen_string_literal: true

class AddAuthorEmailToGpgSignatures < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in a separate migration 20250502053033
  def change
    add_column :gpg_signatures, :author_email, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
