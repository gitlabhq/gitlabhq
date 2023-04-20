# frozen_string_literal: true

class AddCodeSuggestionsToNamespaceSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :namespace_settings, :code_suggestions, :boolean, default: false, null: false
  end
end
