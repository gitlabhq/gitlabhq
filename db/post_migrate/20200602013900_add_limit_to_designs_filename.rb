# frozen_string_literal: true

class AddLimitToDesignsFilename < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit(:design_management_designs, :filename, 255, validate: false)
  end

  def down
    remove_text_limit(:design_management_designs, :filename)
  end
end
