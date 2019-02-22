# frozen_string_literal: true

class RemoveTokenFromPersonalAccessTokens < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :personal_access_tokens, :token, :string
  end
end
