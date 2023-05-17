# frozen_string_literal: true

class ChangeCodeSuggestionsDefaultFalseInNamespaceSettings < Gitlab::Database::Migration[2.1]
  def change
    change_column_default :namespace_settings, :code_suggestions, from: true, to: false
  end
end
