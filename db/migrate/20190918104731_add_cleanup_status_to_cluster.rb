# frozen_string_literal: true

class AddCleanupStatusToCluster < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:clusters, :cleanup_status, # rubocop:disable Migration/AddColumnWithDefault
      :smallint,
      default: 1,
      allow_null: false)
  end

  def down
    remove_column(:clusters, :cleanup_status)
  end
end
