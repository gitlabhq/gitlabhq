# frozen_string_literal: true

class AddGranularToPersonalAccessTokens < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :personal_access_tokens, :granular, :boolean, null: false, default: false
  end
end
