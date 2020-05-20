# frozen_string_literal: true

class AddEncryptedRunnersTokenToProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/AddColumnsToWideTables
  # rubocop:disable Migration/PreventStrings
  def change
    add_column :projects, :runners_token_encrypted, :string
  end
  # rubocop:enable Migration/PreventStrings
  # rubocop:enable Migration/AddColumnsToWideTables
end
