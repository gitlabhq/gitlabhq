# frozen_string_literal: true

class AddEncryptedRunnersTokenToNamespaces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :namespaces, :runners_token_encrypted, :string
  end
end
