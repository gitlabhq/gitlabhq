# frozen_string_literal: true

class AddIndexToServiceUniqueInstancePerType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:services, [:type, :instance], unique: true, where: 'instance IS TRUE')
  end

  def down
    remove_concurrent_index(:services, [:type, :instance])
  end
end
