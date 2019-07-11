# frozen_string_literal: true

class AddTokenEncryptedToDeployTokens < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :deploy_tokens, :token_encrypted, :string
  end
end
