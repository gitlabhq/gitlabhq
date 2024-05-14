# frozen_string_literal: true

class AddTrustedExternUidToIdentities < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  enable_lock_retries!

  def change
    add_column :identities, :trusted_extern_uid, :boolean, default: true
  end
end
