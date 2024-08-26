# frozen_string_literal: true

class AddAliasVersionToSourceUserPlaceholderReference < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    # Setting then removing default to set values for existing data only
    add_column :import_source_user_placeholder_references, :alias_version, :integer, limit: 2, default: 1, null: false
    change_column_default :import_source_user_placeholder_references, :alias_version, from: 1, to: nil
  end
end
