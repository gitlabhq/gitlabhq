# frozen_string_literal: true

class AddNotNullCheckOnIidOnDesignManangementDesigns < ActiveRecord::Migration[6.0]
  include ::Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_not_null_constraint(:design_management_designs, :iid)
  end

  def down
    remove_not_null_constraint(:design_management_designs, :iid)
  end
end
