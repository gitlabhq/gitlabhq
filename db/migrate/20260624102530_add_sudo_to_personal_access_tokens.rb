# frozen_string_literal: true

class AddSudoToPersonalAccessTokens < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :personal_access_tokens, :sudo, :boolean, default: false, null: false
  end
end
