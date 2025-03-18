# frozen_string_literal: true

class AddTokenPrefixesToApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.10'

  CONSTRAINT_NAME = 'check_application_settings_token_prefixes_is_hash'

  def up
    with_lock_retries do
      add_column :application_settings, :token_prefixes, :jsonb, default: {}, null: false, if_not_exists: true
    end

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(token_prefixes) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
    with_lock_retries do
      remove_column :application_settings, :token_prefixes, if_exists: true
    end
  end
end
