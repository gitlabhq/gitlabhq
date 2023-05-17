# frozen_string_literal: true

class ChangeCodeSuggestionsDefaultInNamespaceSettings < Gitlab::Database::Migration[2.1]
  def change
    change_column_default :namespace_settings, :code_suggestions, from: false, to: true
  end
end
