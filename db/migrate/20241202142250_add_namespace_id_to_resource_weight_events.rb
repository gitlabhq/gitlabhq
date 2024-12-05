# frozen_string_literal: true

class AddNamespaceIdToResourceWeightEvents < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :resource_weight_events, :namespace_id, :bigint
  end
end
