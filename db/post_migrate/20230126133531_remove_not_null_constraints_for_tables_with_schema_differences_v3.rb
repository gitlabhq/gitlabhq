# frozen_string_literal: true

class RemoveNotNullConstraintsForTablesWithSchemaDifferencesV3 < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless Gitlab.com?

    change_column_null :integrations, :updated_at, true
    change_column_null :integrations, :created_at, true

    change_column_null :project_settings, :show_default_award_emojis, true
  end

  def down
    # no-op
  end
end
