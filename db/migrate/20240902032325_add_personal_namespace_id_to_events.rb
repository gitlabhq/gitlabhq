# frozen_string_literal: true

class AddPersonalNamespaceIdToEvents < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    add_column :events, :personal_namespace_id, :bigint
  end

  def down
    remove_column :events, :personal_namespace_id
  end
end
