# frozen_string_literal: true

class DropIndexNamespacesOnRequireTwoFactorAuthentication < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  TABLE_NAME = :namespaces
  INDEX_NAME = :index_namespaces_on_require_two_factor_authentication

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :require_two_factor_authentication,
      name: INDEX_NAME
  end
end
