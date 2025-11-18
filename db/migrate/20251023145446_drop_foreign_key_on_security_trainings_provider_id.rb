# frozen_string_literal: true

class DropForeignKeyOnSecurityTrainingsProviderId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    remove_foreign_key_if_exists :security_trainings, column: :provider_id
  end

  def down
    add_concurrent_foreign_key(
      :security_trainings,
      :security_training_providers,
      column: :provider_id,
      on_delete: :cascade,
      validate: true
    )
  end
end
