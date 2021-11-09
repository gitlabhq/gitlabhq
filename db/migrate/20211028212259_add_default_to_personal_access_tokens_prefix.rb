# frozen_string_literal: true

class AddDefaultToPersonalAccessTokensPrefix < Gitlab::Database::Migration[1.0]
  def change
    change_column_default(:application_settings, :personal_access_token_prefix, from: nil, to: 'glpat-')
  end
end
