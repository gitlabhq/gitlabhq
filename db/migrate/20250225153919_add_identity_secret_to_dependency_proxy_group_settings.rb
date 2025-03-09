# frozen_string_literal: true

class AddIdentitySecretToDependencyProxyGroupSettings < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  TABLE_NAME = :dependency_proxy_group_settings

  def up
    with_lock_retries do
      add_column TABLE_NAME, :identity, :jsonb, null: true, if_not_exists: true
      add_column TABLE_NAME, :secret, :jsonb, null: true, if_not_exists: true
    end

    add_check_constraint TABLE_NAME,
      'num_nonnulls(identity, secret) = 2 OR num_nulls(identity, secret) = 2',
      check_constraint_name(TABLE_NAME, 'identity_and_secret', 'both_set_or_null')
  end

  def down
    with_lock_retries do
      remove_column(TABLE_NAME, :identity, if_exists: true)
      remove_column(TABLE_NAME, :secret, if_exists: true)
    end
  end
end
