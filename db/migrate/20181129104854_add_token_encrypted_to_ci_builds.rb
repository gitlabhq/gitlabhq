# frozen_string_literal: true

class AddTokenEncryptedToCiBuilds < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/AddColumnsToWideTables
  # rubocop:disable Migration/PreventStrings
  def change
    add_column :ci_builds, :token_encrypted, :string
  end
  # rubocop:enable Migration/PreventStrings
  # rubocop:enable Migration/AddColumnsToWideTables
end
