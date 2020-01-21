# frozen_string_literal: true

class AddManagedToCluster < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:clusters, :managed, :boolean, default: true) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:clusters, :managed)
  end
end
