# frozen_string_literal: true

class AddTierToCdEnvironments < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    add_column :cd_environments, :tier, :smallint, default: 0, null: false, if_not_exists: true
  end

  def down
    remove_column :cd_environments, :tier, if_exists: true
  end
end
