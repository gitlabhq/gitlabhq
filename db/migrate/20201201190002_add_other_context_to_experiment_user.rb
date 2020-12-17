# frozen_string_literal: true

class AddOtherContextToExperimentUser < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :experiment_users, :context, :jsonb, default: {}, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :experiment_users, :context
    end
  end
end
