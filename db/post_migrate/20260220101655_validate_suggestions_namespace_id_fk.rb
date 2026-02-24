# frozen_string_literal: true

class ValidateSuggestionsNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    validate_foreign_key :suggestions, :namespace_id, name: :fk_35c950f0d6
  end

  def down
    # no-op
  end
end
