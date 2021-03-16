# frozen_string_literal: true

class AddTierToEnvironments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :environments, :tier, :smallint
    end
  end

  def down
    with_lock_retries do
      remove_column :environments, :tier
    end
  end
end
