# frozen_string_literal: true

class AddExternallyVerifiedToGpgKeys < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :gpg_keys, :externally_verified, :boolean, default: false, null: false
  end
end
