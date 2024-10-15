# frozen_string_literal: true

class AddTempMigratingColumnToNamespaceHistoricalStatistics < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    add_column :vulnerability_namespace_historical_statistics, :migrating, :boolean, default: false, null: false
  end

  def down
    remove_column :vulnerability_namespace_historical_statistics, :migrating
  end
end
