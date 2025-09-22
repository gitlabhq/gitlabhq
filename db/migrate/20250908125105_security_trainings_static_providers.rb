# frozen_string_literal: true

class SecurityTrainingsStaticProviders < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    change_column_null :security_trainings, :provider_id, true
    add_column :security_trainings, :training_provider_id, :bigint, null: false, default: 0
  end

  def down
    change_column_null :security_trainings, :provider_id, false
    remove_column :security_trainings, :training_provider_id
  end
end
