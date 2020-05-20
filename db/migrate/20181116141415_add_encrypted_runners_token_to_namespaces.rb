# frozen_string_literal: true

class AddEncryptedRunnersTokenToNamespaces < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :namespaces, :runners_token_encrypted, :string
  end
  # rubocop:enable Migration/PreventStrings
end
