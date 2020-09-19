# frozen_string_literal: true

class AddSeatsCurrentlyInUseInGitlabSubscriptions < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :gitlab_subscriptions, :seats_in_use, :integer, default: 0, null: false
      add_column :gitlab_subscriptions, :seats_owed, :integer, default: 0, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :gitlab_subscriptions, :seats_in_use
      remove_column :gitlab_subscriptions, :seats_owed
    end
  end
end
