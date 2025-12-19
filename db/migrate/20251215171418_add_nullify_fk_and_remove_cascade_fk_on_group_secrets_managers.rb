# frozen_string_literal: true

class AddNullifyFkAndRemoveCascadeFkOnGroupSecretsManagers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  NEW_FK_NAME = 'fk_12159a4355'
  OLD_FK_NAME = 'fk_rails_12159a4355'

  def up
    add_concurrent_foreign_key :group_secrets_managers, :namespaces,
      column: :group_id,
      on_delete: :nullify,
      name: NEW_FK_NAME

    with_lock_retries do
      remove_foreign_key_if_exists :group_secrets_managers, :namespaces,
        name: OLD_FK_NAME
    end
  end

  def down
    add_concurrent_foreign_key :group_secrets_managers, :namespaces,
      column: :group_id,
      on_delete: :cascade,
      name: OLD_FK_NAME

    with_lock_retries do
      remove_foreign_key_if_exists :group_secrets_managers, :namespaces,
        name: NEW_FK_NAME
    end
  end
end
