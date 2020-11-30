# frozen_string_literal: true

class DropFeatureFilterTypeFromUserPreferences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :user_preferences, :feature_filter_type
    end
  end

  def down
    with_lock_retries do
      add_column :user_preferences, :feature_filter_type, :bigint
    end
  end
end
