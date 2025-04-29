# frozen_string_literal: true

class ChangeGeoConcurrencyDefaultSettings < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def up
    change_column_default :geo_nodes, :repos_max_capacity, from: 25, to: 10
    change_column_default :geo_nodes, :verification_max_capacity, from: 100, to: 10
    change_column_default :geo_nodes, :minimum_reverification_interval, from: 7, to: 90
    change_column_default :geo_nodes, :container_repositories_max_capacity, from: 10, to: 2
  end

  def down
    change_column_default :geo_nodes, :repos_max_capacity, from: 10, to: 25
    change_column_default :geo_nodes, :verification_max_capacity, from: 10, to: 100
    change_column_default :geo_nodes, :minimum_reverification_interval, from: 90, to: 7
    change_column_default :geo_nodes, :container_repositories_max_capacity, from: 2, to: 10
  end
end
