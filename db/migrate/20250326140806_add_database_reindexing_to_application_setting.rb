# frozen_string_literal: true

class AddDatabaseReindexingToApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column(:application_settings, :database_reindexing, :jsonb, default: {}, null: false)
  end
end
