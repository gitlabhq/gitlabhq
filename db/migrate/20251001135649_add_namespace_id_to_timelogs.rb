# frozen_string_literal: true

class AddNamespaceIdToTimelogs < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :timelogs, :namespace_id, :bigint, null: false, default: 0
  end
end
