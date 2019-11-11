# frozen_string_literal: true

class AddIndicesToAbuseReports < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :abuse_reports, :user_id
  end

  def down
    remove_concurrent_index :abuse_reports, :user_id
  end
end
