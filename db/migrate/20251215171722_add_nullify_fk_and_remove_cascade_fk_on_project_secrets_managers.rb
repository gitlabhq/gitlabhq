# frozen_string_literal: true

class AddNullifyFkAndRemoveCascadeFkOnProjectSecretsManagers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  NEW_FK_NAME = 'fk_8f88850d11'
  OLD_FK_NAME = 'fk_rails_8f88850d11'

  def up
    add_concurrent_foreign_key :project_secrets_managers, :projects,
      column: :project_id,
      on_delete: :nullify,
      name: NEW_FK_NAME

    with_lock_retries do
      remove_foreign_key_if_exists :project_secrets_managers, :projects,
        name: OLD_FK_NAME
    end
  end

  def down
    add_concurrent_foreign_key :project_secrets_managers, :projects,
      column: :project_id,
      on_delete: :cascade,
      name: OLD_FK_NAME

    with_lock_retries do
      remove_foreign_key_if_exists :project_secrets_managers, :projects,
        name: NEW_FK_NAME
    end
  end
end
