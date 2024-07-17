# frozen_string_literal: true

class AddCodeSuggestionsApiRateLimitToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :application_settings, :code_suggestions_api_rate_limit, :integer, default: 60, null: false
  end
end
