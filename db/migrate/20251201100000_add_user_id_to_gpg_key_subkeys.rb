# frozen_string_literal: true

class AddUserIdToGpgKeySubkeys < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def change
    add_column :gpg_key_subkeys, :user_id, :bigint
  end
end
