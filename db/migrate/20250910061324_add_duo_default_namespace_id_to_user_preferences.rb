# frozen_string_literal: true

class AddDuoDefaultNamespaceIdToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :user_preferences, :duo_default_namespace_id, :bigint
  end
end
