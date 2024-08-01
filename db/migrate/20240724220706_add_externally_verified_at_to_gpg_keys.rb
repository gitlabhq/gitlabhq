# frozen_string_literal: true

class AddExternallyVerifiedAtToGpgKeys < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :gpg_keys, :externally_verified_at, :datetime_with_timezone, null: true
  end
end
