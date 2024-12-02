# frozen_string_literal: true

class AddReachabilityColumnToSbomOccurancesTable < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  def up
    with_lock_retries do
      add_column :sbom_occurrences, :reachability, :smallint, default: 0 # -- Legacy migration
    end
  end

  def down
    with_lock_retries do
      remove_column :sbom_occurrences, :reachability
    end
  end
end
