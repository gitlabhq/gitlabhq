# frozen_string_literal: true

class AddLoggingFieldVariantToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    add_column :application_settings, :logging_settings, :jsonb, default: {}, null: false
  end

  def down
    remove_column :application_settings, :logging_settings
  end
end
