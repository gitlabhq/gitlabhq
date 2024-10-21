# frozen_string_literal: true

class AddTransactionalEmailApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  CONSTRAINT_NAME = 'check_application_settings_transactional_emails_is_hash'

  def up
    add_column :application_settings, :transactional_emails, :jsonb, default: {}, null: false

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(transactional_emails) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
    remove_column :application_settings, :transactional_emails
  end
end
