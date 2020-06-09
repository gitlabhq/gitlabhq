# frozen_string_literal: true

class AddMaxImportSize < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column(:application_settings, :max_import_size, :integer, default: 50, null: false)
  end

  def down
    remove_column(:application_settings, :max_import_size)
  end
end
