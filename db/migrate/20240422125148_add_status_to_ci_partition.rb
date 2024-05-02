# frozen_string_literal: true

class AddStatusToCiPartition < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column(:ci_partitions, :status, :integer, limit: 2, default: 0, null: false)
  end
end
