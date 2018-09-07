# frozen_string_literal: true

class AddUserPingConsentToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :application_settings, :usage_stats_set_by_user_id, :integer
    add_concurrent_foreign_key :application_settings, :users, column: :usage_stats_set_by_user_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :application_settings, column: :usage_stats_set_by_user_id
    remove_column :application_settings, :usage_stats_set_by_user_id
  end
end
