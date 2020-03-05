# frozen_string_literal: true

class AddIndexToServiceUniqueTemplatePerType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:services, [:type, :template], unique: true, where: 'template IS TRUE')
  end

  def down
    remove_concurrent_index(:services, [:type, :template])
  end
end
