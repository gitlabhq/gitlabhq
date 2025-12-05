# frozen_string_literal: true

class CreateCellsOutstandingLeases < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    create_table :cells_outstanding_leases, id: false do |t| # rubocop:disable Migration/EnsureFactoryForTable, Lint/RedundantCopDisableDirective -- No factory needed
      t.primary_key :uuid, :uuid, default: false, null: false
      t.timestamps_with_timezone null: false
    end
  end
end
