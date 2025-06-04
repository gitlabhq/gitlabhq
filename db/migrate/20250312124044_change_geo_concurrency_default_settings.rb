# frozen_string_literal: true

class ChangeGeoConcurrencyDefaultSettings < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  # Some customers somehow took an upgrade path that led to their `geo_nodes` table not having
  # some columns, which caused this migration to error. So we need to check for missing columns
  # and add them. See https://gitlab.com/gitlab-org/gitlab/-/issues/543146

  COLUMN_CONFIGS = [
    { name: :repos_max_capacity, new_default: 10, old_default: 25 },
    { name: :verification_max_capacity, new_default: 10, old_default: 100 },
    { name: :minimum_reverification_interval, new_default: 90, old_default: 7 },
    { name: :container_repositories_max_capacity, new_default: 2, old_default: 10 }
  ]

  def up
    COLUMN_CONFIGS.each do |config|
      if column_exists?(:geo_nodes, config[:name])
        change_column_default(:geo_nodes, config[:name], from: config[:old_default], to: config[:new_default])
      else
        add_column(:geo_nodes, config[:name], :integer, default: config[:new_default])
      end
    end
  end

  def down
    COLUMN_CONFIGS.each do |config|
      if column_exists?(:geo_nodes, config[:name])
        change_column_default(:geo_nodes, config[:name], from: config[:new_default], to: config[:old_default])
      end
    end
  end
end
