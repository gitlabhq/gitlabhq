# frozen_string_literal: true

class AddColumnCreatorIdToNamespaceDetails < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :namespace_details, :creator_id, :bigint
  end
end
