# frozen_string_literal: true

class AddMarkdownSettingsHashConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_application_settings_markdown_settings_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "jsonb_typeof(markdown_settings) = 'object'",
      CONSTRAINT_NAME,
      validate: true
    )
  end

  def down
    remove_check_constraint(:application_settings, CONSTRAINT_NAME)
  end
end
