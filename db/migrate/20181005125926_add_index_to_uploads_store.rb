# frozen_string_literal: true

class AddIndexToUploadsStore < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :uploads, :store
  end

  def down
    remove_concurrent_index :uploads, :store
  end
end
